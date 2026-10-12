const xlsx = require('xlsx');

function dumpData(filePath) {
  console.log(`\n\n--- Reading ${filePath} ---`);
  try {
    const workbook = xlsx.readFile(filePath);
    console.log('Sheet Names:', workbook.SheetNames);
    
    for (const sheetName of workbook.SheetNames) {
      console.log(`\nSheet: ${sheetName}`);
      const worksheet = workbook.Sheets[sheetName];
      const data = xlsx.utils.sheet_to_json(worksheet);
      console.log(`Found ${data.length} rows.`);
      if (data.length > 0) {
        console.log('First 2 rows:');
        console.log(JSON.stringify(data.slice(0, 2), null, 2));
      }
    }
  } catch(e) {
    console.error(e);
  }
}

dumpData('c:\\Users\\krmta\\OneDrive\\Desktop\\pndtbcknd\\frontend\\pandit_ssetu\\assets\\Pooja_Store_App_Product_Master_500Plus.xlsx');
