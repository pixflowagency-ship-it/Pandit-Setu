const xlsx = require('xlsx');

function dumpData(filePath) {
  console.log(`\n\n--- Reading ${filePath} ---`);
  try {
    const workbook = xlsx.readFile(filePath);
    const firstSheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[firstSheetName];
    const data = xlsx.utils.sheet_to_json(worksheet);
    console.log(`Found ${data.length} rows.`);
    console.log('First 3 rows:');
    console.log(JSON.stringify(data.slice(0, 3), null, 2));
    if (data.length > 0) {
      console.log('Keys available:');
      console.log(Object.keys(data[0]));
    }
  } catch(e) {
    console.error(e);
  }
}

dumpData('c:\\Users\\krmta\\OneDrive\\Desktop\\pndtbcknd\\frontend\\pandit_ssetu\\assets\\Pandit Ji Data.xlsx');
dumpData('c:\\Users\\krmta\\OneDrive\\Desktop\\pndtbcknd\\frontend\\pandit_ssetu\\assets\\Pooja_Store_App_Product_Master_500Plus.xlsx');
