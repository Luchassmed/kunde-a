const { test, login, requestAccess } = require('../common/lib/isc');

// Kundespecifik værdi - en rolle der reelt findes i kunde-a's access request-katalog.
const ROLE_NAME = 'TestRole';

test('anmod om adgang til en rolle via access request-kataloget', async ({ page }) => {
  test.setTimeout(60000);
  await login(page);
  await requestAccess(page, ROLE_NAME);
});
