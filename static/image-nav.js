// Minimal keyboard navigation for image pages
document.addEventListener('keydown', function(e) {
    if (e.key === 'ArrowLeft') {
        const prevLink = document.querySelector('.nav-button.prev');
        if (prevLink && prevLink.href !== '#') {
            window.location.href = prevLink.href;
        }
    } else if (e.key === 'ArrowRight') {
        const nextLink = document.querySelector('.nav-button.next');
        if (nextLink && nextLink.href !== '#') {
            window.location.href = nextLink.href;
        }
    }
});