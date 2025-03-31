document.getElementById('submitBtn').addEventListener('click', async () => {
  let apiUrl = window.WORLD_API || "";
  if (apiUrl.startsWith("http://api:")) {
    const parts = apiUrl.split(':');
    const port = parts[2];
    apiUrl = `http://${window.location.hostname}:${port}`;
  }

  const queryType = document.getElementById('queryType').value;
  const queryInput = document.getElementById('queryInput').value.trim();
  const resultDiv = document.getElementById('result');

  if (!queryInput) {
    alert('Please enter a name to query!');
    return;
  }

  const encodedQuery = encodeURIComponent(queryInput);
  const queryUrl = `${apiUrl}/${queryType}?name=${encodedQuery}`;

  try {
    const response = await fetch(queryUrl, { mode: 'cors' });
    const data = await response.json();
    if (response.ok) {
      resultDiv.style.display = 'block';
      resultDiv.innerHTML = `<pre>${JSON.stringify(data, null, 2)}</pre>`;
    } else {
      resultDiv.style.display = 'block';
      resultDiv.innerHTML = `<p>Error: ${data.message || 'Unknown error'}</p>`;
    }
  } catch (error) {
    resultDiv.style.display = 'block';
    resultDiv.innerHTML = `<p>Error: Could not fetch data.</p>`;
  }
});

