(function (Drupal) {
  Drupal.behaviors.scrollCards = {
    attach(context) {
      once('scroll-cards', '.block-cards', context).forEach((block) => {
        const cards = block.querySelectorAll('.c-card');

        const observer = new IntersectionObserver(
          (entries, obs) => {
            entries.forEach(entry => {
              if (entry.isIntersecting) {
                cards.forEach((card, index) => {
                  card.style.setProperty('--anim-delay', `${index * 150}ms`);
                  card.classList.add('card-visible');
                });
                obs.unobserve(block);
              }
            });
          },
          {
            threshold: 0.2,
          }
        );

        observer.observe(block);
      });
    }
  };
})(Drupal);