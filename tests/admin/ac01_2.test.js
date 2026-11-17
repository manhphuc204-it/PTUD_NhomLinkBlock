// Jest test for AC01.2 - Create new room with admin rights
const request = require('supertest');
const api = request('http://localhost:3000');

describe('Admin Room Creation', () => {
  const adminToken = 'PLACEHOLDER_ADMIN_TOKEN';

  test('AC01.2 - POST /admin/rooms creates a room', async () => {
    const payload = {
      name: 'New Room',
      capacity: 10
    };
    const res = await api
      .post('/admin/rooms')
      .send(payload)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('id');
    expect(res.body.name).toBe(payload.name);
  });
});
