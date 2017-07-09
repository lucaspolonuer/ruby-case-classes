# ruby-case-classes
Éste es un proyecto académico desarrollado usando metaprogramación en Ruby. La idea es permitir estructuras inmutables del paradigma funcional en un lenguaje de objetos como Ruby.

### Case Classes

Como primer requerimiento, se pide implementar las abstracciones necesarias para poder modelar Case Classes en el lenguaje Ruby. Llamaremos “Case Class” a aquellas clases cuyas instancias sean inmutables y puedan ser definidas mediante la siguiente sintaxis:
```rubycase_class X do
  #definición de métodos y atributos
end
```
Las case classes deben poder definir comportamiento para sí mismas, incluir módulos normalmente y extender de cualquier clase normal; sin embargo, no debe ser posible que ninguna otra clase las extienda.
```ruby
module M
  def m1() 5 end
end
class C
  def m2() 7 end
end
case_class X < C do
  include M
  def self.m3() 9 end
end
un_x = X.new
un_x.m1  # Retorna 5
un_x.m2  # Retorna 7
X.m3     # Retorna 9
class Y < X # Error! No se puede extender una case class!
```
En casi todos los sentidos una case class debe ser y comportarse igual a cualquier otra clase, con las siguientes excepciones:

### Función constructora
Al no poder modificar las instancias de una clase es natural que la creación de nuevas instancias ocurra con mayor frecuencia. Siendo ese el caso, es deseable que la instanciación de una case classes sea lo menos verbosa posible, para hacer el código más expresivo. Para eso queremos poder construir nuevas instancias con la siguiente sintaxis:
```ruby
case_class Alumno do
  attr_accessor :nombre, :nota
end
case_class Curso do
  attr_accessor :materia, :codigo, :alumnos
end
# No es necesario el new!
curso = Curso("TADP", "k3031", [
  Alumno("Jose", 8),
  Alumno.new("Miguel", 2)
])
```

### Instancias inmutables

De más está decir que las instancias creadas a partir de case classes no deben poder sufrir cambios de estado. Para garantizar esto, queremos redefinir el comportamiento de attr_accessor para que sólo genere getters (similar a lo que hace attr_reader).
```ruby
case_class Alumno do
  attr_accessor :nombre, :nota
end
alumno = Alumno("Jose", 8)
alumno.nombre       # Retorna "jose"
alumno.nombre = 10  # Error! El método nombre= no está definido!
Queremos también forzar el envío del mensaje freeze a cada nueva instancia, para prevenir cualquier tipo de mal uso.
case_class Alumno do
  attr_accessor :nombre, :nota
  def hacer_trampa
    @nota = 10
  end
end
alumno = Alumno("Miguel", 2)
alumno.hacer_trampa # Error!
```

### Buenos defaults

Para simplificar sus definiciones y evitar código repetitivo, las case classes proveen a sus instancias una implementación por defecto de los métodos to_s, == y hash.
Las implementaciones por defecto deben ser las siguientes:
```
to_s: Retorna el nombre de la case class del receptor, seguido del valor de sus atributos entre paréntesis, separados por coma.
==: Retorna true si el parámetro es una instancia de la misma case class que el receptor y todos sus atributos son iguales.
hash: Retorna 7, más la sumatoria del hash de los atributos.
```
```ruby
alumno = Alumno("Jose", 8)
otro_alumno_igual = Alumno("Jose", 8)
otro_alumno_distinto = Alumno("Miguel", 2)
alumno.to_s                    # Retorna "Alumno(Jose, 8)"
alumno == otro_alumno_igual    # Retorna true
alumno == otro_alumno_distinto # Retorna false
alumno.hash                    # Retorna -799690864674641430
```
Es muy importante notar que estos métodos por defecto SÓLO deben generarse si no se definen por otro medio, es decir, no deben sobreescribir implementaciones presentes en el cuerpo de la case_class o heredadas de un módulo o superclase distinta de Object.
```ruby
module M
  def to_s() "Soy un M"
end
class C
  def to_s() "Soy un C"
end
case_class X < C
case_class Y
  include M
end
case_class Z
  def to_s() "Soy un Z"
end
X().to_s  # Retorna "Soy un C"
Y().to_s  # Retorna "Soy un M"
Z().to_s  # Retorna "Soy un Z"
```
### Copiado inteligente

Al trabajar de forma inmutable las operaciones que de otro modo serían destructivas son reemplazadas por consultas que retornan un nuevo objeto que representa cómo sería el receptor si realizara dicho cambio. Esto vuelve muy recurrente la necesidad de copiar un objeto cambiando ligeramente algún aspecto.
Se pide que las instancias de las case classes respondan a un mensaje copy que retorne una nueva instancia, con el mismo estado interno que el receptor.
```ruby
alumno = Alumno("Jose", 8)
otro_alumno = alumno.copy
alumno == otro_alumno  # Retorna true
```
Además debe ser posible evaluar el método copy pasando expresiones lambda de aridad 1 por parámetro, para determinar nuevos valores para los atributos del receptor. Cada lambda recibida debe evaluarse sobre el atributo del receptor que lleve el mismo nombre que el parámetro y el resultado debe reemplazar a valor original en la nueva copia.
```ruby
case_class Alumno do
  attr_accessor :nombre, :nota
end
alumno = Alumno("Jose", 8)
otro_alumno = alumno.copy ->(nota){nota + 1}
otro_alumno.nombre  # Retorna "Jose"
otro_alumno.nota    # Retorna 9
otro_alumno_mas = alumno.copy ->(nombre){"Arturo"}, ->(nota){5}
otro_alumno_mas.nombre  # Retorna "Arturo"
otro_alumno_mas.nota    # Retorna 5
alumno.copy ->(edad){25} # Error! No existe el atributo "edad"
```
### Case Objects

No siempre es necesario tener múltiples instancias de un tipo, especialmente cuando no es posible cambiar el estado interno de las mismas. En los casos en que una construcción inmutable no requiere atributos, o una única instancia es suficiente para realizar una tarea, la instanciación de una clase se vuelve una molestia sin sentido.
Queremos, para estos casos, tener la posibilidad de definir un único objeto inmutable, utilizando una sintaxis similar a la de las case classes.
```ruby
case_object X do
  #definición de métodos
end
```
Las definiciones de case objects son similares a las de case classes, pero definen una única instancia y no admiten la definición de atributos. A todos los efectos, estos objetos se comportan igual que las instancias de case classes pero, dado que no pueden tener atributos, las respuestas de sus métodos to_s no llevan paréntesis y al copiarse se retornan a sí mismos.
```ruby
case_class Alumno do
  attr_accessor :nombre, :estado
end
case_object Cursando do
end
case_class Termino do
  attr_accessor :nota
end
alumno = Alumno("Jose", Cursando)
otro_alumno = Alumno("Matias", Termino(9))
alumno.to_s    # Responde "Alumno(Jose, Cursando)"
```

### Pattern Matching

Ahora que tenemos construcciones inmutables como en funcional, sería bueno poder trabajarlas de la misma manera. Para eso vamos a agregar la posibilidad de trabajar nuestras instancias inmutables utilizando Pattern Matching.
Lo que buscamos es poder analizar un objeto inmutable y elegir una pieza de código para evaluar dependiendo de si el mismo cumple o no determinadas restricciones sobre su forma.
En lugar de crear una sintaxis especial para esto, vamos a extender los case statements de Ruby (otro nombre para el viejo y querido switch) para que soporten comparar aplicando patrones.
```ruby
case objeto_inmutable
  when patron_1
   # qué hacer si el objeto matchea con el patron_1
  when patron_2
   # qué hacer si el objeto matchea con el patron_2
  ...
  else
   # qué hacer si el objeto no matchea ningún patrón
end
```
Realizar esta extensión es fácil si sabemos que Ruby compara los patrones de su case statement enviandoles el mensaje === con el objeto a analizar por parámetro. Esto significa que sólo tenemos que implementar dicho mensaje en nuestros patrones, haciendo que respondan si matchean (o no) con el receptor.
Los patrones a implementar son los siguientes:
a) Cualquier cosa

El caso más sencillo de patrón es aquel que acepta cualquier elemento como válido. Vamos a representar este patrón con el nombre “_”.
```ruby
case alumno
  when _ #Siempre entra por acá
    5
end
```
Este patrón no parece muy útil por ahora (especialmente existiendo el else), pero va a ser importante más adelante. ; )
b) Pertenecer a un tipo

Este patrón matchea cuando el objeto tiene entre sus ancestros al tipo especificado.
```ruby
alumno = Alumno("Jose", 9)
valor = case alumno
  when is_a Array  # El patrón falla: alumno no es un array
    5
  when is_a Alumno # El patrón pasa: alumno es de tipo alumno
    7
end
valor              # Debe ser 7
```
c) Tener cierto valor en un atributo

Este patrón recibe el nombre de un atributo y un valor y matchea siempre y cuando el valor de dicho atributo sea el esperado. En caso de que el objeto no tenga definido dicho atributo el patrón sólo debe fallar sin lanzar ningún error.
```ruby
alumno = Alumno("Jose", 9)
valor = case alumno
  when has(:nombre, "Raul") # El patrón falla: el nombre no es "Raul"
    5
  when has(:apellido, nil)  # El patrón falla: no hay atributo apellido
    7
  when has(:nota, 9)        # El patrón matchea
    3
end
valor                       # Debe ser 3
```
c) Comparación Estructural

Por último, queremos poder utilizar la estructura de nuestros objetos inmutables como patrón. Para eso, vamos a convertir a las instancias de case classes y case objects en patrones!
En este caso, no solamente debemos definir el ===, sino que debemos poder construir patrones compuestos instanciando nuestras case_cases utilizando otros patrones como parámetro.
```ruby
alumno = Alumno("Jose", Termino(9))
valor = case alumno
  when Alumno(“Jose”, Termino(7)) # Falla: la nota no coincide.
    5
  when Alumno(“Jose”, Aprobo)     # Falla: el estado no coincide.
    7
  when Alumno(_, has(:nota, 9))   # Pasa! el nombre no importa y el estado tiene nota 9.
    3
end
valor                             # Debe ser 3
```
