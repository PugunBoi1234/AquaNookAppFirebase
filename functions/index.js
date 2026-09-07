const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.deleteProductsWhenUserDeleted = functions.auth.user().onDelete(async (user) => {
  const db = admin.firestore();
  const products = await db.collection('products').where('sellerId', '==', user.uid).get();

  if (products.empty) {
    return null;
  }

  for (let start = 0; start < products.docs.length; start += 500) {
    const batch = db.batch();
    products.docs.slice(start, start + 500).forEach((product) => batch.delete(product.ref));
    await batch.commit();
  }
  return null;
});
