Kameleon bootstrap recipes
--------------------------

The defaults bootstrap kameleon recipes.

These recipes are made to do the **bootstrap from scratch** for all
distributions. However, as this process is tricky it is maintained only for
the Qemu backend.

These recipes produce two files for each recipe build:

- *recipe*.tar.gz
- *recipe*-cache.tar.gz

You can produce those files using the ``build.sh`` script.

Those files can be used as based for an other recipe. The [Kameleon
recipes](https://github.com/oar-team/kameleon-recipes) is using it.

It can be used as templates to create your own recipes. See:
http://kameleon.imag.fr/getting_started.html#create-a-new-recipe-from-template
