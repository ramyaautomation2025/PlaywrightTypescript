import { test, expect } from '@playwright/test';

test.describe('Dummy API Tests', () => {
  test('GET request - fetch user data', async ({ request }) => {
    const response = await request.get('https://jsonplaceholder.typicode.com/users/1');

    expect(response.status()).toBe(200);
    
    const user = await response.json();
    
    expect(user).toHaveProperty('id');
    expect(user).toHaveProperty('name');
    expect(user).toHaveProperty('email');
    expect(user.id).toBe(1);
  });

  test('POST request - create a new post', async ({ request }) => {
    const response = await request.post('https://jsonplaceholder.typicode.com/posts', {
      data: {
        title: 'Test Post',
        body: 'This is a test post created by Playwright',
        userId: 1,
      },
    });

    expect(response.status()).toBe(201);
    
    const post = await response.json();
    
    expect(post).toHaveProperty('id');
    expect(post.title).toBe('Test Post');
    expect(post.userId).toBe(1);
  });

  test('GET request - fetch all posts', async ({ request }) => {
    const response = await request.get('https://jsonplaceholder.typicode.com/posts?userId=1');

    expect(response.status()).toBe(200);
    
    const posts = await response.json();
    
    expect(Array.isArray(posts)).toBeTruthy();
    expect(posts.length).toBeGreaterThan(0);
    expect(posts[0]).toHaveProperty('userId', 1);
  });

  test('PUT request - update a post', async ({ request }) => {
    const response = await request.put('https://jsonplaceholder.typicode.com/posts/1', {
      data: {
        id: 1,
        title: 'Updated Post Title',
        body: 'Updated body content',
        userId: 1,
      },
    });

    expect(response.status()).toBe(200);
    
    const updatedPost = await response.json();
    
    expect(updatedPost.title).toBe('Updated Post Title');
    expect(updatedPost.id).toBe(1);
  });

  test('DELETE request - remove a post', async ({ request }) => {
    const response = await request.delete('https://jsonplaceholder.typicode.com/posts/1');

    expect(response.status()).toBe(200);
  });

  test('Verify API response headers', async ({ request }) => {
    const response = await request.get('https://jsonplaceholder.typicode.com/users/1');

    expect(response.status()).toBe(200);
    expect(response.headers()['content-type']).toContain('application/json');
  });
});
