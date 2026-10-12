document.querySelectorAll('.copy').forEach((btn) => {
  btn.addEventListener('click', async () => {
    const target = document.getElementById(btn.dataset.copy);
    if (!target) return;
    try {
      await navigator.clipboard.writeText(target.innerText);
    } catch {
      const range = document.createRange();
      range.selectNodeContents(target);
      const sel = window.getSelection();
      sel.removeAllRanges();
      sel.addRange(range);
      document.execCommand('copy');
    }
    btn.textContent = '已复制';
    btn.classList.add('done');
    setTimeout(() => {
      btn.textContent = '复制';
      btn.classList.remove('done');
    }, 1600);
  });
});
