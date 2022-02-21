# Inspect
De la palabra en inglés inspect; 'inspector' de tipos en Lua.<br>
Puedes usar este modulo de varias maneras e instalarlo con `lit` en: [luvit](https://www.luvit.io).

Puedes escanear tablas (`{}`) y `userdata` como la que obtienes con: `io.open('inspect.lua', ...)`, un ejemplo del mismo:

``` lua
local handle = io.open('-test')
p(handle, type(handle))
print(require'inspect'(handle))
```

Y obtendrás cómo resultado:

![image](https://user-images.githubusercontent.com/74837790/154875376-d7e56f1a-d068-42cf-9ac2-5f21df57886c.png)

Como pudiste notar los métodos son separados al principio o indirectamente los indíces que comiencen con '__' que se toman de manera mas relevante.

# Instalación

```
lit install Corotyest/inspect
```

# Funciones

## inspect:`encode(list, tabs, tag)` o `inspect(...)`

Cualquier argumento pasado en `list` es convertiendo en `string`, puedes específicar cierta cantidad de `tabs` para el cáracter especíal `'\n'`, el argumento `tag` es usado para identificar `userdata` pero no necesario usarse (convencionalmente).

## inspect:`makeField(_index, _value, tabs)`

Crea una línea de una tabla en base a `_index` y `_value` al igual que [encode](https://github.com/Corotyest/inspect#inspectencodelist-tabs-tag-o-inspect); regresa una `string` convertido.

## inspect:`getn(list)`

Regresa la cantidad de líneas que tiene `list`.
