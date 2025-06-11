document.getElementById('submitBtn').addEventListener('click', async () => {
  const apiUrl     = '/api';
  const queryType  = document.getElementById('queryType').value;
  const queryInput = document.getElementById('queryInput').value.trim();
  const resultDiv  = document.getElementById('result');

  if (!queryInput) {
    alert('Please enter a name to query!');
    return;
  }

  const encodedQuery = encodeURIComponent(queryInput);
  const queryUrl     = `${apiUrl}/${queryType}?name=${encodedQuery}`;

  try {
    const response = await fetch(queryUrl);
    const data     = await response.json();
    resultDiv.style.display = 'block';

    if (response.ok) {
      resultDiv.innerHTML = `<pre>${JSON.stringify(data, null, 2)}</pre>`;
    } else {
      resultDiv.innerHTML = `<p>Error: ${data.message || 'Unknown error'}</p>`;
    }
  } catch (err) {
    resultDiv.style.display = 'block';
    resultDiv.innerHTML = `<p>Error: Could not fetch data.</p>`;
  }
});

