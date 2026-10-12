const xlsx = require('xlsx');
const fs = require('fs');
const path = require('path');

const assetsDir = 'c:\\Users\\krmta\\OneDrive\\Desktop\\pndtbcknd\\frontend\\pandit_ssetu\\assets\\data';
if (!fs.existsSync(assetsDir)) {
  fs.mkdirSync(assetsDir, { recursive: true });
}

// 1. Pandit Data
try {
  const pPath = 'c:\\Users\\krmta\\OneDrive\\Desktop\\pndtbcknd\\frontend\\pandit_ssetu\\assets\\Pandit Ji Data.xlsx';
  const pWorkbook = xlsx.readFile(pPath);
  const pData = xlsx.utils.sheet_to_json(pWorkbook.Sheets[pWorkbook.SheetNames[0]]);
  fs.writeFileSync(path.join(assetsDir, 'pandits.json'), JSON.stringify(pData, null, 2));
  console.log('Saved pandits.json');
} catch (e) {
  console.error(e);
}

// 2. Pooja Products
try {
  const prodPath = 'c:\\Users\\krmta\\OneDrive\\Desktop\\pndtbcknd\\frontend\\pandit_ssetu\\assets\\Pooja_Store_App_Product_Master_500Plus.xlsx';
  const prodWorkbook = xlsx.readFile(prodPath);
  const prodData = xlsx.utils.sheet_to_json(prodWorkbook.Sheets['Product_Master']);
  fs.writeFileSync(path.join(assetsDir, 'products.json'), JSON.stringify(prodData, null, 2));
  console.log('Saved products.json');
} catch (e) {
  console.error(e);
}
