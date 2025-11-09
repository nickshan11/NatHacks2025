from flask import Flask, jsonify, request
from flask_cors import CORS
from models import db, setup_db
from routes import blueprint_api

def create_app():
    app = Flask(__name__)
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///mydatabase.db'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    CORS(app)
    setup_db(app)  # from models

    app.register_blueprint(blueprint_api, url_prefix='/api')

    @app.route('/')
    def hello():
        return jsonify({'message': 'Welcome to NatHacks2025 API'})

    return app

if __name__ == '__main__':
    app = create_app()
    app.run(debug=True)

