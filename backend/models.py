from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

def setup_db(app):
    db.init_app(app)
    with app.app_context():
        db.create_all()

class Item(db.Model):
    __tablename__ = 'items'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    description = db.Column(db.String(500))

    def format(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description
        }
