(function() {
  document.addEventListener('click', function(e) {
    var button = e.target.closest('.video-embed__show');
    if (!button) return;

    var container = button.closest('.video-embed--youtube');
    if (!container) return;

    var videoId = container.dataset.videoEmbedId;
    var params = container.dataset.videoEmbedParams;
    var allowAutoplay = container.dataset.videoEmbedAllow === 'true';
    
    var queryParts = [];
    if (params) queryParts.push(params);
    if (allowAutoplay) queryParts.push('autoplay=1');
    var query = queryParts.length > 0 ? '?' + queryParts.join('&') : '';

    var allowParts = ['encrypted-media', 'picture-in-picture'];
    if (allowAutoplay) {
      allowParts.push('autoplay');
    }

    var iframe = document.createElement('iframe');
    iframe.src = 'https://www.youtube-nocookie.com/embed/' + videoId + query;
    iframe.allow = allowParts.join('; ');
    iframe.allowFullscreen = true;
    iframe.loading = 'lazy';
    iframe.style.cssText = 'position:absolute;top:0;left:0;width:100%;height:100%;border:none;';

    container.innerHTML = '';
    container.appendChild(iframe);
  });

  // Progressive enhancement: upgrade to maxresdefault if available
  document.querySelectorAll('.video-embed--youtube').forEach(function(container) {
    var videoId = container.dataset.videoEmbedId;
    var imgEl = document.getElementById('yt-thumb-' + videoId);
    if (!imgEl) return;

    var test = new Image();
    test.onload = function() {
      if ((test.naturalWidth || 0) >= 640 || (test.naturalHeight || 0) >= 480) {
        var maxres = 'https://i.ytimg.com/vi/' + videoId + '/maxresdefault.jpg';
        var existing = imgEl.getAttribute('srcset') || '';
        imgEl.setAttribute('srcset', maxres + ' 1280w, ' + existing);
        if (window.innerWidth >= 640 || window.devicePixelRatio >= 2) {
          imgEl.src = maxres;
        }
      }
    };
    test.src = 'https://i.ytimg.com/vi/' + videoId + '/maxresdefault.jpg';
  });
})();
