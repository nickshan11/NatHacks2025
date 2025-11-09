import sys
import serial
import serial.tools.list_ports
import csv
import os
import time
from collections import deque

from PyQt6.QtWidgets import *
from PyQt6.QtCore import QThread, pyqtSignal
import pyqtgraph as pg

# --- Configuration ---
BAUD_RATE = 115200
NUM_CHANNELS = 6
PACKET_LEN = NUM_CHANNELS * 2 + 3 + 1  # 16 bytes
SYNC1 = 0xC7
SYNC2 = 0x7C
END_BYTE = 0x01

# --- Worker Thread for Serial Reading ---
class SerialReader(QThread):
    data_received = pyqtSignal(str)
    packet_decoded = pyqtSignal(list)

    def __init__(self, port, baud, log_csv=False):
        super().__init__()
        self.port = port
        self.baud = baud
        self.log_csv = log_csv
        self.running = False
        self.ser = None
        self.csv_file = None
        self.csv_writer = None

    def run(self):
        try:
            self.ser = serial.Serial(self.port, self.baud, timeout=1)
            self.running = True

            if self.log_csv:
                script_dir = os.path.dirname(os.path.abspath(__file__))
                csv_path = os.path.join(script_dir, 'biosignals.csv')
                self.csv_file = open(csv_path, 'w', newline='')
                self.csv_writer = csv.writer(self.csv_file)
                self.csv_writer.writerow(['ElapsedTime', 'Counter'] + [f'CH{i}' for i in range(NUM_CHANNELS)])
            
            start_time = time.time()
            buffer = bytearray()

            while self.running:
                if self.ser.in_waiting:
                    buffer.extend(self.ser.read(self.ser.in_waiting))
                    while len(buffer) >= PACKET_LEN:
                        if buffer[0] == SYNC1 and buffer[1] == SYNC2:
                            packet = buffer[:PACKET_LEN]
                            buffer = buffer[PACKET_LEN:]
                            if packet[-1] == END_BYTE:
                                counter, values = self.decode_packet(packet)
                                text = f"{counter}: {values}"
                                self.data_received.emit(text)
                                self.packet_decoded.emit(values)
                                if self.csv_writer:
                                    elapsed = time.time() - start_time
                                    self.csv_writer.writerow([f"{elapsed:.3f}", counter] + values)
                            else:
                                buffer.pop(0)
                        elif buffer[0] == 0x2 and buffer[1] == 0x0 and buffer[2] == 0x0:
                            packet = buffer[:PACKET_LEN]
                            buffer = buffer[PACKET_LEN:]
                            if packet[-1] == 0x2:
                                command = [chr(i) for i in packet[3:PACKET_LEN-1] if i != 0]
                                command = ''.join(command).encode('utf-8')
                                command = str(command, 'utf-8')
                                self.data_received.emit(command)
                        else:
                            buffer.pop(0)
        except serial.SerialException as e:
            self.data_received.emit(f"Serial error: {e}")
        finally:
            if self.csv_file:
                self.csv_file.close()
            if self.ser and self.ser.is_open:
                self.ser.close()

    def stop(self):
        self.running = False

    def decode_packet(self, packet):
        counter = packet[2]
        values = []
        for i in range(NUM_CHANNELS):
            high = packet[3 + 2 * i]
            low = packet[4 + 2 * i]
            val = (high << 8) | low
            values.append(val)
        return counter, values

# --- Main GUI Window ---
class SerialTerminal(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Chord LSL Bluetooth Terminal")
        self.resize(900, 600)

        layout = QVBoxLayout()
        top_row = QHBoxLayout()

        # Port selection
        self.port_label = QLabel("Port:")
        self.port_box = QComboBox()
        self.refresh_ports()
        self.refresh_button = QPushButton("Refresh")
        self.refresh_button.clicked.connect(self.refresh_ports)

        self.connect_button = QPushButton("Connect")
        self.connect_button.clicked.connect(self.toggle_connection)

        top_row.addWidget(self.port_label)
        top_row.addWidget(self.port_box)
        top_row.addWidget(self.refresh_button)
        top_row.addWidget(self.connect_button)

        # Plot area
        self.plot_widget = pg.PlotWidget(title="ECG Signals")
        self.plot_widget.setYRange(0, 4096)  # assuming 12-bit ADC
        self.plot_widget.showGrid(x=True, y=True)
        self.plot_widget.addLegend()

        self.plot_curves = []
        for i in range(NUM_CHANNELS):
            pen = pg.mkPen(color=pg.intColor(i), width=2)
            curve = self.plot_widget.plot(pen=pen, name=f"CH{i}")
            self.plot_curves.append(curve)

        # Data buffers
        self.buffer_len = 500  # ~4 seconds at 125Hz
        self.data_buffers = [deque([0]*self.buffer_len, maxlen=self.buffer_len) for _ in range(NUM_CHANNELS)]

        # Terminal area
        self.output = QTextEdit()
        self.output.setReadOnly(True)

        # Command line
        bottom_row = QHBoxLayout()
        self.input = QLineEdit()
        self.input.returnPressed.connect(self.send_command)
        self.send_button = QPushButton("Send")
        self.send_button.clicked.connect(self.send_command)
        bottom_row.addWidget(self.input)
        bottom_row.addWidget(self.send_button)

        # Layout setup
        layout.addLayout(top_row)
        layout.addWidget(self.plot_widget)
        layout.addWidget(self.output)
        layout.addLayout(bottom_row)
        self.setLayout(layout)

        # Serial thread placeholder
        self.reader_thread = None

    def refresh_ports(self):
        self.port_box.clear()
        ports = serial.tools.list_ports.comports()
        for port in ports:
            self.port_box.addItem(port.device)

    def toggle_connection(self):
        if self.reader_thread and self.reader_thread.running:
            # Disconnect
            self.send_stop()
            self.reader_thread.stop()
            self.reader_thread.wait()
            self.reader_thread = None
            self.connect_button.setText("Connect")
            self.output.append("Disconnected.\n")
        else:
            # Connect
            port = self.port_box.currentText()
            if not port:
                self.output.append("No port selected.\n")
                return

            self.reader_thread = SerialReader(port, BAUD_RATE, log_csv=True)
            self.reader_thread.data_received.connect(self.display_data)
            self.reader_thread.packet_decoded.connect(self.update_plot)
            self.reader_thread.start()
            self.connect_button.setText("Disconnect")
            self.output.append(f"Connecting to {port}\n")

    def send_command(self):
        cmd = self.input.text().strip()
        if not cmd:
            return
        if self.reader_thread and self.reader_thread.ser:
            self.reader_thread.ser.write((cmd + '\n').encode('utf-8'))
            self.output.append(f"> {cmd}")
            self.input.clear()
        else:
            self.output.append("Not connected.\n")
    
    def send_stop(self):
        if self.reader_thread and self.reader_thread.ser:
            self.reader_thread.ser.write(("STOP" + '\n').encode('utf-8'))
            self.output.append(f"> Disconnecting...")
            self.input.clear()

    def display_data(self, text):
        self.output.append(text)

    def update_plot(self, values):
        for i, val in enumerate(values):
            self.data_buffers[i].append(val)
            self.plot_curves[i].setData(list(self.data_buffers[i]))


def main():
    app = QApplication(sys.argv)
    win = SerialTerminal()
    win.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
