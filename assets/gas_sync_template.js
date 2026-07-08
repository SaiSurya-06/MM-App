// Google Apps Script - Money Manager Partner Sync
// Deploy as: Web App | Execute as: Me | Who has access: Anyone

function doGet(e) {
  var params = e.parameter;
  var action = params.action;
  
  if (action === "test") {
    return ContentService.createTextOutput("ok").setMimeType(ContentService.MimeType.TEXT);
  }
  
  var sheet = getOrCreateSheet();
  
  if (action === "get") {
    var key = params.key;
    var val = getValueByKey(sheet, key);
    if (val === null) {
      return ContentService.createTextOutput("404").setMimeType(ContentService.MimeType.TEXT);
    }
    return ContentService.createTextOutput(val).setMimeType(ContentService.MimeType.TEXT);
  }
  
  if (action === "set_chunk") {
    var key = params.key;
    var index = parseInt(params.index);
    var total = parseInt(params.total);
    var val = params.val;
    
    // Store chunk
    var chunkKey = key + "_chunk_" + index;
    setValueByKey(sheet, chunkKey, val);
    
    // Check if all chunks are present
    var allChunks = [];
    var missing = false;
    for (var i = 0; i < total; i++) {
      var cVal = getValueByKey(sheet, key + "_chunk_" + i);
      if (cVal === null) {
        missing = true;
        break;
      }
      allChunks.push(cVal);
    }
    
    if (!missing) {
      // Assemble and save
      var fullVal = allChunks.join("");
      setValueByKey(sheet, key, fullVal);
      
      // Clean up chunk rows
      for (var i = 0; i < total; i++) {
        deleteRowByKey(sheet, key + "_chunk_" + i);
      }
      return ContentService.createTextOutput("assembled").setMimeType(ContentService.MimeType.TEXT);
    }
    
    return ContentService.createTextOutput("chunk_received").setMimeType(ContentService.MimeType.TEXT);
  }
  
  return ContentService.createTextOutput("error: unknown action").setMimeType(ContentService.MimeType.TEXT);
}

function getOrCreateSheet() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName("SyncData");
  if (!sheet) {
    sheet = ss.insertSheet("SyncData");
    sheet.appendRow(["Key", "Value", "UpdatedAt"]);
    sheet.setFrozenRows(1);
    sheet.getRange("B:B").setNumberFormat("@");
  }
  return sheet;
}

function getValueByKey(sheet, key) {
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (data[i][0] == key) {
      return data[i][1];
    }
  }
  return null;
}

function setValueByKey(sheet, key, value) {
  var data = sheet.getDataRange().getValues();
  var dateStr = new Date().toISOString();
  var found = false;
  
  for (var i = 1; i < data.length; i++) {
    if (data[i][0] == key) {
      if (!found) {
        var cell = sheet.getRange(i + 1, 2);
        cell.setValue("'" + value);
        sheet.getRange(i + 1, 3).setValue(dateStr);
        found = true;
      } else {
        sheet.deleteRow(i + 1);
        data.splice(i, 1);
        i--;
      }
    }
  }
  if (!found) {
    sheet.appendRow([key, "'" + value, dateStr]);
  }
}

function deleteRowByKey(sheet, key) {
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (data[i][0] == key) {
      sheet.deleteRow(i + 1);
      data.splice(i, 1);
      i--;
    }
  }
}
