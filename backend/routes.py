from flask import Blueprint, jsonify, request
from models import Item, db

blueprint_api = Blueprint('api', __name__)

@blueprint_api.route('/items', methods=['GET'])
def get_items():
    items = Item.query.all()
    formatted = [i.format() for i in items]
    return jsonify({'success': True, 'items': formatted})

@blueprint_api.route('/items', methods=['POST'])
def create_item():
    body = request.get_json()
    name = body.get('name')
    description = body.get('description')
    if not name:
        return jsonify({'success': False, 'message': 'Name is required'}), 400

    item = Item(name=name, description=description)
    db.session.add(item)
    db.session.commit()
    return jsonify({'success': True, 'item': item.format()}), 201

@blueprint_api.route('/items/<int:item_id>', methods=['PATCH'])
def update_item(item_id):
    item = Item.query.get(item_id)
    if not item:
        return jsonify({'success': False, 'message': 'Item not found'}), 404
    body = request.get_json()
    if 'name' in body:
        item.name = body['name']
    if 'description' in body:
        item.description = body['description']
    db.session.commit()
    return jsonify({'success': True, 'item': item.format()})

@blueprint_api.route('/items/<int:item_id>', methods=['DELETE'])
def delete_item(item_id):
    item = Item.query.get(item_id)
    if not item:
        return jsonify({'success': False, 'message': 'Item not found'}), 404
    db.session.delete(item)
    db.session.commit()
    return jsonify({'success': True, 'deleted_id': item_id})

