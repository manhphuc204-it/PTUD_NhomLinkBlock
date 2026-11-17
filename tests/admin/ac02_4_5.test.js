// Jest test cases for AC02.4 (list users) and AC02.5 (update user)
const request = require('supertest');
const api = request('http://localhost:3000'); // adjust base URL as needed

describe('Admin Users API', () => {
  const adminToken = 'PLACEHOLDER_ADMIN_TOKEN'; // replace with real token

  test('AC02.4 - GET /admin/users returns user list', async () => {
    const res = await api
      .get('/admin/users')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  test('AC02.5 - PATCH /admin/users/:id updates user info', async () => {
    const userId = 'TK001'; // example user ID from seed
    const updatePayload = { name: 'Updated Name' };
    const res = await api
      .patch(`/admin/users/${userId}`)
      .send(updatePayload)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(200);
    expect(res.body.name).toBe(updatePayload.name);
  });
});
