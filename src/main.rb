module CCContainer
    def case_class(name, superclass, &blk)
      superclass = ::Object if superclass.nil?
      #Este bloque tiene el contexto en el que se creo. no el contexto de Class. Tenerlo en cuenta
      blk_padre = Proc.new {
        #1
        define_singleton_method :attr_accessor do |*several_variants|
          attr_reader *several_variants
        end

        define_method :copy do |*lambdas|
          nueva_instancia = self.dup #dup clonea y desfrizea
          lambdas.each {|lam|
            raise 'Error! Las lambda para el copy deben tener 1 parametro' if lam.arity != 1
            atributo_evaluado = lam.parameters.first[1]
            raise 'Error! El atributo ' + atributo_evaluado + 'no existe' unless nueva_instancia.instance_variables.include?("@#{atributo_evaluado}".to_sym)
            nueva_instancia.instance_variable_set("@#{atributo_evaluado}", lam.call(instance_variable_get("@#{atributo_evaluado}")))
          }
          nueva_instancia.freeze
          return nueva_instancia
        end

      }
      new_case_class = Class.new(superclass, &blk_padre)

      #Se evalua el bloque que se pasó en la definición
      new_case_class.class_eval &blk

      new_case_class.class_eval do
        #1.2 Las case_clases no pueden extenderse
        def self.inherited(subclass)
          raise ArgumentError, 'Error! No se puede extender una case class!'
        end

        def comparar_atributos otro_elemento
          #genero 2 arrays con nombres de atributos
          atributos_mios = self.instance_variables
          atributos_otro = otro_elemento.instance_variables

          #genero 2 arrays con valores de esos atributos
          valores_mios = Array.new
          atributos_mios.each do |var|
            valores_mios.push(self.instance_variable_get(var))
          end
          valores_otro = Array.new
          atributos_otro.each do |var|
            valores_otro.push(otro_elemento.instance_variable_get(var))
          end

          if atributos_mios.length != atributos_otro.length || valores_mios.length != valores_otro.length
            return false
          end

          #comparar nombre de atributos
          nombres_son_iguales = atributos_mios.map.with_index {|x, i| x.=== atributos_otro[i]}.all?
          #comparar valor atributos
          valores_son_iguales = valores_mios.map.with_index {|x, i| x.=== valores_otro[i]}.all?

          return nombres_son_iguales && valores_son_iguales

        end

        #Pisar el metodo to_s solo si ninguna superclase lo define
        if (instance_method(:to_s).owner == Kernel)
          def to_s
            ar = self.instance_variables
            s = self.class.to_s
            unless ar.size == 0 then
              s = s + "("
              ar.each do |var|
                s = s + self.instance_variable_get(var).to_s
                s = s + "," unless var == ar.last
              end
              s = s + ")"
            end
            s
          end
        end
        #Pisar el metodo == solo si ninguna superclase lo define
        if (instance_method(:==).owner == BasicObject)
          def == otro_elemento
            return self.class.equal?(otro_elemento.class) && self.comparar_atributos(otro_elemento)
          end
        end
        #Pisar el metodo hash solo si ninguna superclase lo define
        if (instance_method(:hash).owner == Kernel)
          def hash
            ar = self.instance_variables
            sum = 0
            ar.each do |var|
              sum = sum + self.instance_variable_get(var).hash
            end
            res = 7 + sum
          end
        end
      end

      new_case_class
    end
end

Object.include(CCContainer)

#Inicializador de case class. Su función es habilitar la herencia
# con '< NombreSuperClase'
class CaseClassInitializer
  attr_accessor :nombre_clase, :una_superclase

  def initialize nombreClase
    @nombre_clase = nombreClase
  end

  def < superclase
    @una_superclase = superclase
    return self
  end

end


class CCContext

  def self.ejecutar(&blk)
    contexto = new
    begin
      resultado = contexto.instance_eval(&blk)
      resultado
    rescue => e
      raise e
    ensure
      #Siempre limpiar las constantes, incluso en los casos donde se levanta una excepcion
      contexto.limpiar_constantes
    end
  end

  def lista_case_classes
    @case_classes ||= []
  end

  def setear_constante(nombre, obj)
    ::Object.const_set(nombre, obj)
  end

  def limpiar_constantes
    lista_case_classes.each do |nombre|
      ::Object.send(:remove_const, nombre)
    end
  end

  #1.1 definir case_classes con la sintaxis
  #'case_class X < SuperClass do...'
  def case_class(initializer, &blk)
    nombre_clase = initializer.nombre_clase
    superclase = initializer.una_superclase

    c = ::Object.case_class(nombre_clase, superclase, &blk) #clase

    #1.A FUNCIÓN CONSTRUCTORA ej. UnaClaseClass()
    self.define_singleton_method(nombre_clase) {|*args|
      instancia = c.new(*args)
      instancia.freeze
      instancia
    }

    setear_constante(nombre_clase, c)
    #agrego la case_class a la lista para limpiarlas al eliminar el contexto
    lista_case_classes << nombre_clase

    return c

  end

  #2. Case Objects
  def case_object (una_case_class_initializer, &blk)
    raise ArgumentError unless una_case_class_initializer.una_superclase.nil?
    un_case_object = case_class(una_case_class_initializer, &blk)

    instancia = un_case_object.new
    raise ArgumentError, "Un Case object no puede tener atributos" unless instancia.instance_variables.empty?

    instancia.define_singleton_method(:copy) {
      return self
    }

    # Se sobreescribe la case_class creada para este simbolo
    # y en la constante se guarda una instancia (CaseObject) en lugar de una clase
    setear_constante(una_case_class_initializer.nombre_clase, instancia)
  end

  #3. Pattern Matching
  # Patrones:
  def _
    PatronComparacion.new {true}
  end

  def is_a tipo
    PatronComparacion.new {|objeto| objeto.is_a? tipo}
  end

  def has atributo, valor
    PatronComparacion.new() {|objeto|
      objeto.instance_variables.include?("@#{atributo}".to_sym) &&
          objeto.instance_variable_get("@#{atributo}") === valor}
  end

  class PatronComparacion
    def initialize &blk
      @blk = blk
    end

    def === objeto
      @blk.call(objeto)
    end
  end

end #CCContext end

def Object.const_missing(name)
  ::CaseClassInitializer.new(name)
end


CCContext.ejecutar do
  # case_class Alumno do
  #   attr_accessor :nombre, :estado
  #
  #   def initialize nombre, estado
  #     @nombre = nombre
  #     @estado = estado
  #   end
  #
  #   def === otro
  #     self.== otro
  #   end
  # end
  # case_class Termino do
  #   attr_accessor :nota
  #
  #   def initialize nota
  #     @nota = nota
  #   end
  #
  #   def === otro
  #     self.== otro
  #   end
  # end

  # p 'debugear'
  # case Alumno("Jose", Termino(9))
  #   when (Alumno(_, Termino(9))) # deberia entrar
  #     p 'entro'
  #   when _
  #     p 'cayo en _'
  # end


  # class P
  # end
  # case_class X < P do
  #   attr_accessor :edad
  #   def initialize edad
  #     @edad = edad
  #   end
  #   def === algo
  #     self.== algo
  #   end
  #   def saludar
  #     'hola'
  #   end
  # end

  # case X(25)
  #    when X(25)
  #      p 'soy igual a X'
  #    when has(:edad, 25)
  #      p 'entre en el has'
  #    when is_a(Alumno)
  #      p 'entre en is_a'
  #    when _
  #      p 'entre en _'
  #  end

  # case_class C do
  #   def initialize(alumno, acelga)
  #     @alumno = alumno
  #     @acelga = acelga
  #   end
  # end
  # p X().to_s #deberia dar soy un P
  # p C(5, 7).to_s #deberia dar nuestra implementacion
  #
  # a = C(3, 5)
  # b = a.copy
  # c = b.copy ->(alumno){alumno + 5}, ->(acelga){0}
  #
  # p a
  # p b
  # p c
end

