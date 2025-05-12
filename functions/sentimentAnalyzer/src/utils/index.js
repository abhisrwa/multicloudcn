function stringToTimeString(dateString) {
  try {
    const date = new Date(dateString);
    if (isNaN(date.getTime())) {
      return "Invalid Date";
    }
    return date.getTime();
  } catch (error) {
    return "Error: Invalid date string format";
  }
}

module.exports = {
    stringToTimeString
};