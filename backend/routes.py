from flask import Blueprint, jsonify, request
from datetime import datetime, timedelta
from random import randint
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

# Sleep scores endpoint
@blueprint_api.route('/devices/<string:device_id>/sleep-scores', methods=['GET'])
def get_sleep_scores(device_id):
    """Return mock sleep scores for a given device and month.
    Query params: month=YYYY-MM (defaults to current month)
    Response: { deviceId: str, month: str, scores: [{ date: YYYY-MM-DD, score: int }] }
    """
    month = request.args.get('month')
    today = datetime.utcnow()
    if not month:
        month = today.strftime('%Y-%m')
    try:
        month_start = datetime.strptime(month + '-01', '%Y-%m-%d')
    except ValueError:
        return jsonify({'success': False, 'message': 'Invalid month format, expected YYYY-MM'}), 400

    # Determine number of days in month
    if month_start.month == 12:
        next_month = datetime(month_start.year + 1, 1, 1)
    else:
        next_month = datetime(month_start.year, month_start.month + 1, 1)
    days_in_month = (next_month - month_start).days

    scores = []
    for day in range(days_in_month):
        date = month_start + timedelta(days=day)
        # Mock score 50-100, lightly vary by weekday for pseudo realism
        base = 60 + (date.weekday() * 3)  # weekday effect
        score = min(100, max(50, base + randint(-10, 15)))
        scores.append({'date': date.strftime('%Y-%m-%d'), 'score': score})

    return jsonify({
        'success': True,
        'deviceId': device_id,
        'month': month,
        'scores': scores
    })

