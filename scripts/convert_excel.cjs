const xlsx = require('xlsx');
const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const assetsDir = path.join(repoRoot, 'frontend', 'pandit_ssetu', 'assets', 'data');

if (!fs.existsSync(assetsDir)) {
  fs.mkdirSync(assetsDir, { recursive: true });
}

// 1. Pandit Data
try {
  const pPath = path.join(repoRoot, 'frontend', 'pandit_ssetu', 'assets', 'Pandit Ji Data.xlsx');
  if (fs.existsSync(pPath)) {
    const pWorkbook = xlsx.readFile(pPath);
    const pData = xlsx.utils.sheet_to_json(pWorkbook.Sheets[pWorkbook.SheetNames[0]]);
    fs.writeFileSync(path.join(assetsDir, 'pandits.json'), JSON.stringify(pData, null, 2));
    console.log('Saved pandits.json');
  } else {
    console.warn(`Pandit Ji Data.xlsx not found at ${pPath}`);
  }
} catch (e) {
  console.error('Error converting pandit data:', e);
}

// 2. Pooja Products
try {
  const prodPath = path.join(repoRoot, 'frontend', 'pandit_ssetu', 'assets', 'Pooja_Store_App_Product_Master_500Plus.xlsx');
  if (fs.existsSync(prodPath)) {
    const prodWorkbook = xlsx.readFile(prodPath);
    const prodData = xlsx.utils.sheet_to_json(prodWorkbook.Sheets['Product_Master']);
    fs.writeFileSync(path.join(assetsDir, 'products.json'), JSON.stringify(prodData, null, 2));
    console.log('Saved products.json');
  } else {
    console.warn(`Product master excel not found at ${prodPath}`);
  }
} catch (e) {
  console.error('Error converting products data:', e);
}
