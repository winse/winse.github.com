(function () {
  const path = window.location.pathname.replace(/\/index\.html$/, "/").replace(/\/$/, "") || "/";

  document.querySelectorAll("[data-nav]").forEach((link) => {
    const target = link.getAttribute("data-nav").replace(/\/$/, "") || "/";
    const current = path === "" ? "/" : path;
    if (target === current || (target !== "/" && current.startsWith(target))) {
      link.classList.add("nav-link-active");
    }
  });

  const navToggle = document.getElementById("nav-toggle");
  const mobileNav = document.getElementById("mobile-nav");
  if (navToggle && mobileNav) {
    navToggle.addEventListener("click", () => {
      const open = mobileNav.classList.toggle("hidden") === false;
      navToggle.setAttribute("aria-expanded", String(open));
    });
  }

  function escapeHtml(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function createPostCard(post) {
    const article = document.createElement("article");
    article.dataset.categories = (post.categories || []).join(",");

    const category = post.categories && post.categories[0];
    const updatedLabel = post.updatedLabel ? `<span aria-hidden="true">·</span><span class="text-xs text-muted">更新 ${escapeHtml(post.updatedLabel)}</span>` : "";
    const description = post.description
      ? `<p class="mt-3 line-clamp-2 text-sm leading-7 text-muted">${escapeHtml(post.description)}</p>`
      : "";
    const cover = post.cover
      ? `<a href="${escapeHtml(post.url)}" class="post-card-cover shrink-0 self-center" aria-hidden="true" tabindex="-1">
          <img src="${escapeHtml(post.cover)}" alt="" loading="lazy" decoding="async" class="post-card-cover-img">
        </a>`
      : "";

    article.className = "card-post group flex gap-5";
    article.innerHTML = `
      <div class="min-w-0 flex-1">
        <div class="meta-row mb-4">
          ${category ? `<span class="rounded-full bg-accent-soft/70 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-accent">${escapeHtml(category)}</span>` : ""}
          <time datetime="${escapeHtml(post.date)}">${escapeHtml(post.dateLabel)}</time>
          ${updatedLabel}
          <span aria-hidden="true">·</span>
          <span>${escapeHtml(post.readingTime)}</span>
        </div>
        <h2 class="post-card-title">
          <a href="${escapeHtml(post.url)}" class="transition hover:text-accent">${escapeHtml(post.title)}</a>
        </h2>
        ${description}
      </div>
      ${cover}
    `;

    return article;
  }

  function initHomeInfiniteScroll() {
    const feedEl = document.getElementById("posts-feed");
    const listEl = document.getElementById("post-list");
    const sentinel = document.getElementById("load-sentinel");
    const loadStatus = document.getElementById("load-status");
    const filterCount = document.getElementById("filter-count");
    const filters = document.getElementById("category-filters");

    if (!feedEl || !listEl || !sentinel) return;

    const pageSize = Number(listEl.dataset.pageSize || 10);
    const allPosts = JSON.parse(feedEl.textContent || "[]");

    let activeCategory = "all";
    let filteredPosts = allPosts.slice();
    let renderedCount = 0;
    let loading = false;

    const updateStatus = () => {
      if (!loadStatus) return;
      if (renderedCount >= filteredPosts.length) {
        loadStatus.textContent =
          filteredPosts.length === 0 ? "No posts in this category" : "All posts loaded";
        sentinel.classList.add("hidden");
      } else {
        loadStatus.textContent = "Scroll for more…";
        sentinel.classList.remove("hidden");
      }
      if (filterCount) {
        filterCount.textContent = `Showing ${Math.min(renderedCount, filteredPosts.length)} of ${filteredPosts.length}`;
      }
    };

    const loadMore = () => {
      if (loading || renderedCount >= filteredPosts.length) return;
      loading = true;

      const batch = filteredPosts.slice(renderedCount, renderedCount + pageSize);
      const fragment = document.createDocumentFragment();
      batch.forEach((post) => fragment.appendChild(createPostCard(post)));
      listEl.appendChild(fragment);
      renderedCount += batch.length;

      loading = false;
      updateStatus();
    };

    const resetAndRender = () => {
      listEl.innerHTML = "";
      renderedCount = 0;
      filteredPosts =
        activeCategory === "all"
          ? allPosts.slice()
          : allPosts.filter((post) => (post.categories || []).includes(activeCategory));
      loadMore();
    };

    if (filters) {
      filters.addEventListener("click", (e) => {
        const btn = e.target.closest("[data-category]");
        if (!btn) return;
        activeCategory = btn.getAttribute("data-category") || "all";
        filters.querySelectorAll(".category-chip").forEach((chip) => {
          chip.classList.remove("chip-active");
        });
        btn.classList.add("chip-active");
        resetAndRender();
      });
    }

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) loadMore();
        });
      },
      { rootMargin: "240px 0px" }
    );
    observer.observe(sentinel);

    resetAndRender();
  }

  initHomeInfiniteScroll();

  function buildToc(listEl, headings) {
    if (!listEl) return;
    listEl.innerHTML = "";
    headings.forEach((h) => {
      if (!h.id) return;
      const li = document.createElement("li");
      const a = document.createElement("a");
      a.href = "#" + h.id;
      a.textContent = h.textContent.replace(/^#\s*/, "");
      if (h.tagName === "H3") a.classList.add("ml-3");
      li.appendChild(a);
      listEl.appendChild(li);
    });
  }

  const content = document.getElementById("post-content");
  const toc = document.getElementById("toc");
  const tocList = document.getElementById("toc-list");
  const tocInline = document.getElementById("toc-inline");
  const tocListInline = document.getElementById("toc-list-inline");

  if (content) {
    const headings = [...content.querySelectorAll("h2, h3")];
    if (headings.length) {
      if (toc) toc.classList.remove("hidden");
      if (tocInline) tocInline.classList.remove("hidden");
      buildToc(tocList, headings);
      buildToc(tocListInline, headings);

      const links = [
        ...document.querySelectorAll("#toc-list a, #toc-list-inline a"),
      ];

      const observer = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (!entry.isIntersecting) return;
            links.forEach((link) => {
              link.classList.toggle(
                "is-active",
                link.getAttribute("href") === "#" + entry.target.id
              );
            });
          });
        },
        { rootMargin: "-20% 0px -70% 0px", threshold: 0 }
      );

      headings.forEach((heading) => observer.observe(heading));
    }
  }
})();
