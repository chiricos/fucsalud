# Plantillas Twig

Todas las plantillas Twig del tema. Usadas por el **Subagente C**.

Aplica `{theme_name}` en todas las ocurrencias antes de crear los archivos.

---

### `templates/includes/header.html.twig`

```twig
<header id="header" class="header" role="banner" aria-label="{{ 'Site header'|t }}">
  {% if page.header %}
    <div class="header__brand">
      {{ page.header }}
    </div>
  {% endif %}

  <button class="nav-toggler" type="button" aria-expanded="false" aria-controls="header-main-nav" aria-label="{{ 'Toggle main navigation'|t }}">
    <span class="visually-hidden">{{ 'Main menu'|t }}</span>
    <svg class="open" width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect y="4" width="24" height="2" fill="currentColor"/>
      <rect y="11" width="24" height="2" fill="currentColor"/>
      <rect y="18" width="24" height="2" fill="currentColor"/>
    </svg>
    <svg class="close" width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <line x1="4" y1="4" x2="20" y2="20" stroke="currentColor" stroke-width="2"/>
      <line x1="20" y1="4" x2="4" y2="20" stroke="currentColor" stroke-width="2"/>
    </svg>
  </button>

  {% if page.menu %}
    <div class="header__nav" id="header-main-nav" role="navigation" aria-label="{{ 'Main navigation'|t }}" aria-hidden="true">
      {{ page.menu }}
    </div>
  {% endif %}
</header>
```

---

### `templates/includes/footer.html.twig`

```twig
<footer class="footer" role="contentinfo">
  <div class="container">
    {% if page.footer %}
      <div class="footer__region">
        {{ page.footer }}
      </div>
    {% endif %}
  </div>
</footer>
```

---

### `templates/layout/page.html.twig`

```twig
{#
/**
 * @file
 * Default theme implementation to display a single page.
 *
 * @see template_preprocess_page()
 * @see html.html.twig
 */
#}

{% block header %}
  {% include '@{theme_name}/includes/header.html.twig' %}
{% endblock %}

{% block tabs %}
  <div class="main-container main-tabs">
    {{ page.tabs }}
  </div>
{% endblock %}

{% block main %}
  <main role="main">
    <a id="main-content" tabindex="-1"></a>
    {% block content %}
      {{ page.content }}
    {% endblock %}
  </main>
{% endblock %}

{% block footer %}
  {% include '@{theme_name}/includes/footer.html.twig' %}
{% endblock %}
```

---

### `templates/layout/html.html.twig`

```twig
{#
/**
 * @file
 * Default theme implementation for the basic structure of a single Drupal page.
 *
 * @see template_preprocess_html()
 */
#}
<!DOCTYPE html>
<html{{ html_attributes }}>
<head>
  <head-placeholder token="{{ placeholder_token }}">
    <title>{{ head_title|safe_join(' | ') }}</title>
    <css-placeholder token="{{ placeholder_token }}">
      <js-placeholder token="{{ placeholder_token }}">
        {% if meta_description %}
          <meta name="description" content="{{ meta_description|escape }}">
        {% endif %}
        {% if meta_image %}
          <meta property="og:image" content="{{ meta_image }}">
          <meta name="twitter:image" content="{{ meta_image }}">
        {% endif %}
</head>
<body{{ attributes }}>
<a href="#main-content" class="visually-hidden focusable">
  {{ 'Skip to main content'|t }}
</a>
{{ page_top }}
{{ page }}
{{ page_bottom }}
<js-bottom-placeholder token="{{ placeholder_token }}">
</body>
</html>
```
