(function () {
  const grid = document.getElementById('projects-grid');
  const list = window.PROJECTS || [];

  if (grid) {
    grid.innerHTML = list
      .map((p) => {
        const url = p.url || `${p.name}/`;
        const tags = (p.tags || []).map((t) => `<span class="pill">${t}</span>`).join('');
        const status = p.status === 'live' ? '<span class="pill live">已上线</span>' : '<span class="pill">筹备中</span>';
        return `
        <a class="pcard" href="${url}" style="--dot:${p.dot || '#4aa8ff'}">
          <h3>${p.title}</h3>
          <p>${p.desc || ''}</p>
          <div class="meta">${status}${tags}</div>
        </a>`;
      })
      .join('');
  }

  const count = document.getElementById('count');
  if (count) count.textContent = String(list.length);

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
})();
