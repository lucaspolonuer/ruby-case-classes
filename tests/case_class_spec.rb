require 'rspec'
require_relative '../src/main.rb'

describe 'Tp_Case_class' do

  context 'Tests' do

    it 'deberia dar true' do
      expect(true).to be(true)
    end

    it 'deberia definir una nueva case_class' do
      result = CCContext.ejecutar do
        case_class UnaCaseClass do
        end
      end
      expect(result).to be_a(Class)
    end

    it 'puede instanciarse una clase con la sintaxis UnaCaseClass()' do
      resultado = CCContext.ejecutar do

        case_class UnaCaseClass do
        end
        #Guardo la instancia y la clase en un array
        resultado = Array.new
        resultado.push(UnaCaseClass())
        resultado.push(UnaCaseClass)
      end
      expect(resultado[0]).to be_an_instance_of(resultado[1])
    end

    it 'puede instanciarse una clase con la sintaxis UnaCaseClass(*params)' do
      resultado = CCContext.ejecutar do
        case_class UnaCaseClass do
          attr_accessor :nombre, :edad

          def initialize(nombre, edad)
            @nombre = nombre
            @edad = edad
          end
        end
        UnaCaseClass("Juan", 21)
      end
      expect(resultado.nombre).to eq("Juan")
      expect(resultado.edad).to eq(21)
    end

    it 'la case class puede extender comportamiento para si mismas, incluir modulos y extender de clases' do
      class A
        def ext_clase
          "extendio de clase padre"
        end
      end

      module B
        def ext_modulo
          "extendio de modulo"
        end
      end
      resultado = CCContext.ejecutar do
        case_class UnaCaseClass < A do
          include B
          attr_accessor :nombre, :edad

          def initialize(nombre, edad)
            @nombre = nombre
            @edad = edad
          end

          def ext_case_class
            "extendio de si misma"
          end
        end
        UnaCaseClass("Juan", 21)
      end
      expect(resultado.ext_clase).to eq("extendio de clase padre")
      expect(resultado.ext_modulo).to eq("extendio de modulo")
      expect(resultado.ext_case_class).to eq("extendio de si misma")

    end

    it 'no se puede extender de una case_class' do
      expect {
        CCContext.ejecutar do
          case_class UnaCaseClass do
            attr_accessor :nombre, :edad

            def initialize(nombre, edad)
              @nombre = nombre
              @edad = edad
            end
          end
          case_class OtraCaseClass < UnaCaseClass do

          end
        end
      }.to raise_error(ArgumentError)
    end

    it 'la instancia de la case_class es inmutable' do
      resultado = CCContext.ejecutar do
        case_class UnaCaseClass do
          attr_accessor :nombre, :edad

          def initialize(nombre, edad)
            @nombre = nombre
            @edad = edad
          end
        end
        instancia = UnaCaseClass("Juan", 21)
        instancia
      end
      expect {resultado.nombre = "Pepe"}.to raise_error(NoMethodError)
      expect {resultado.edad = 30}.to raise_error(NoMethodError)
    end

    it 'queremos enviar el mensaje freeze a cada instancia para prevenir cualquier tipo de mal uso' do
      resultado = CCContext.ejecutar do
        case_class UnaCaseClass do
          attr_accessor :nombre, :nota

          def initialize(nombre, nota)
            @nombre = nombre
            @edad = nota
          end

          def hacer_trampa
            @nota = 10
          end
        end
        instancia = UnaCaseClass("Juan", 4)
        instancia
      end
      expect {resultado.hacer_trampa}.to raise_error(RuntimeError)
    end

    it 'to_s default imprime Nombre y atributos' do
      resultado = CCContext.ejecutar do
        case_class UnaCaseClass do
          attr_accessor :nombre, :nota

          def initialize(nombre, edad)
            @nombre = nombre
            @edad = edad
          end
        end
        UnaCaseClass("Juan", 21).to_s
      end
      expect(resultado).to eq("UnaCaseClass(Juan,21)")
    end

    it 'to_s default imprime Nombre si no tiene atributos' do
      resultado = CCContext.ejecutar do
        case_class UnaCaseClass do

        end
        UnaCaseClass().to_s
      end
      expect(resultado).to eq("UnaCaseClass")
    end

    it '==  Retorna true si es una instancia de la misma case class que el receptor y todos sus atributos son iguales.' do
      resultado = CCContext.ejecutar do
        case_class UnaCaseClass do
          attr_accessor :nombre, :edad

          def initialize(nombre, edad)
            @nombre = nombre
            @edad = edad
          end
        end
        instancia = UnaCaseClass("juan", 8)
        otra_instancia = UnaCaseClass("juan", 8)

        instancia == otra_instancia
      end
      expect(resultado).to be(true)
    end

    it '==  Retorna false si NO es una instancia de la misma case class que el receptor pero todos sus atributos son iguales.' do
      resultado = CCContext.ejecutar do
        case_class UnaCaseClass do
          attr_accessor :nombre, :edad

          def initialize(nombre, edad)
            @nombre = nombre
            @edad = edad
          end
        end
        case_class OtraCaseClass do
          attr_accessor :nombre, :edad

          def initialize(nombre, edad)
            @nombre = nombre
            @edad = edad
          end
        end
        instancia = UnaCaseClass("juan", 8)
        otra_instancia = OtraCaseClass("juan", 8)
        instancia == otra_instancia
      end
      expect(resultado).to be(false)
    end

    it '==  Retorna false si NO es una instancia de la misma case class que el receptor pero todos sus atributos son iguales.' do
      resultado = CCContext.ejecutar do
        case_class UnaCaseClass do
          attr_accessor :nombre, :edad

          def initialize(nombre, edad)
            @nombre = nombre
            @edad = edad
          end
        end
        case_class OtraCaseClass do
          attr_accessor :nombre, :edad

          def initialize(nombre, edad)
            @nombre = nombre
            @edad = edad
          end
        end
        instancia = UnaCaseClass("juan", 8)
        otra_instancia = OtraCaseClass("juan", 8)

        instancia == otra_instancia
      end
      expect(resultado).to be(false)
    end

    it '==  Retorna false si es una instancia de la misma case class que el receptor pero todos sus atributos son distintos.' do
      resultado = CCContext.ejecutar do
        case_class UnaCaseClass do
          attr_accessor :nombre, :edad

          def initialize(nombre, edad)
            @nombre = nombre
            @edad = edad
          end
        end
        instancia = UnaCaseClass("juan", 8)
        otra_instancia = UnaCaseClass("Pedro", 10)

        instancia == otra_instancia
      end
      expect(resultado).to be(false)
    end

    it 'Retorna true si hash' do
      resultado = CCContext.ejecutar do
        case_class UnaCaseClass do
          attr_accessor :nombre, :edad

          def initialize(nombre, edad)
            @nombre = nombre
            @edad = edad
          end
        end
        instancia = UnaCaseClass("Juan", 8)
        instancia.hash
      end
      expect(resultado)
    end

    it 'Retorna "to_s pisado dentro de case_class" si se piso el default para to_s dentro de la clase UnaCaseClass' do
      resultado = CCContext.ejecutar do
        case_class UnaCaseClass do
          attr_accessor :nombre, :edad

          def initialize(nombre, edad)
            @nombre = nombre
            @edad = edad
          end

          def to_s
            "to_s pisado dentro de case_class"
          end
        end
        instancia = UnaCaseClass("juan", 8)
        instancia.to_s
      end
      expect(resultado).to eq("to_s pisado dentro de case_class")
    end

    it 'Retorna "Soy un A" si se piso el default para to_s dentro de una clase A' do
      class A
        def to_s
          "Soy un A"
        end

      end
      resultado = CCContext.ejecutar do
        case_class UnaCaseClass < A do
          attr_accessor :nombre, :edad

          def initialize(nombre, edad)
            @nombre = nombre
            @edad = edad
          end
        end
        instancia = UnaCaseClass("juan", 8)
        instancia.to_s
      end
      expect(resultado).to eq("Soy un A")
    end

    it 'Retorna "Soy un M" si se piso el default para to_s dentro de un modulo M' do #falla

      module M
        def to_s
          "Soy un M"
        end
      end
      resultado = CCContext.ejecutar do

        case_class UnaCaseClass do

          include M

        end
        instancia = UnaCaseClass()
        instancia.to_s
      end
      expect(resultado).to eq("Soy un M")
    end

    it 'copy devuelve una instancia con el mismo estado interno del receptor' do

      resultado = CCContext.ejecutar do
        case_class UnaCaseClass do
          attr_accessor :nombre, :edad

          def initialize(nombre, edad)
            @nombre = nombre
            @edad = edad
          end
        end
        instancia = UnaCaseClass("Juan", 8)
        otra_instancia = instancia.copy

        #para comparar el estado interno (==) debemos hacerlo dentro del contexto
        instancia == otra_instancia
      end
      expect(resultado).to be(true)
    end

    it 'copy recibe una lambda y modifica los atributos' do

      resultado = CCContext.ejecutar do
        case_class UnaCaseClass do
          attr_accessor :nombre, :edad

          def initialize(nombre, edad)
            @nombre = nombre
            @edad = edad
          end
        end
        instancia = UnaCaseClass("Juan", 8)
        instancia.copy ->(edad) {edad + 10}
      end
      expect(resultado.nombre).to eq("Juan")
      expect(resultado.edad).to eq(18)
    end

    it 'definir un case_object genera una instancia' do
      resultado = CCContext.ejecutar do
        case_object UnCaseObject do
        end
      end
      #¿rspec no soporta 'not'?
      expect(resultado.respond_to?(:new)).to be false
    end

    it 'to_s de CaseObject' do
      resultado = CCContext.ejecutar do
        case_class Alumno do
          attr_accessor :nombre, :estado

          def initialize(nombre, estado)
            @nombre = nombre
            @estado = estado
          end
        end
        case_object Cursando do

        end
        alumno = Alumno("Jose", Cursando)
        alumno.to_s
      end
      expect(resultado).to eq("Alumno(Jose,Cursando)")
    end

    it 'copy de CaseObject ' do
      resultado = CCContext.ejecutar do
        case_class Alumno do
          attr_accessor :nombre, :estado

          def initialize(nombre, estado)
            @nombre = nombre
            @estado = estado
          end
        end
        case_object Cursando do

        end
        alumno = Alumno("Jose", Cursando)
        otro_alumno = alumno.copy
        otro_alumno.to_s
      end
      expect(resultado).to eq("Alumno(Jose,Cursando)")
    end

    it 'no se puede crear un case_object con atributos' do
      expect {
        CCContext.ejecutar do
        case_object X do
          def initialize edad = 25
            @edad = edad
          end
        end
      end
      }.to raise_error("Un Case object no puede tener atributos")
    end
    it 'patron _ siempre matchea' do
      resultado = CCContext.ejecutar do
        case_class Alumno do
          attr_accessor :nombre, :estado

          def initialize(nombre, estado)
            @nombre = nombre
            @estado = estado
          end
        end
        alumno = Alumno("Jose", 8)
        case alumno
          when _
            "Matcheo con _"
        end
      end
      expect(resultado).to eq("Matcheo con _")
    end

    it 'patron is_a matchea si el objeto tiene entre sus ancestros al tipo especificado' do
      resultado = CCContext.ejecutar do
        case_class Alumno do
          attr_accessor :nombre, :estado

          def initialize(nombre, estado)
            @nombre = nombre
            @estado = estado
          end
        end
        alumno = Alumno("Jose", 8)
        valor = case alumno
                  when is_a(Array)
                    "Alumno es un arreglo"
                  when is_a(Alumno)
                    "Alumno es un Alumno"
                  when _
                    "Matcheo con _"
                end
        valor
      end
      expect(resultado).to eq("Alumno es un Alumno")
    end

    it 'patron has recibe el nombre de un atributo y un valor y matchea siempre y cuando el valor de dicho atributo sea el esperado.' do
      resultado = CCContext.ejecutar do
        case_class Alumno do
          attr_accessor :nombre, :edad

          def initialize(nombre, edad)
            @nombre = nombre
            @edad = edad
          end
        end
        alumno = Alumno("Jose", 8)
        valor = case alumno
                  when has(:nombre, "Raul")
                    "Alumno no es Raul"
                  when has(:apellido, nil)
                    "Alumno no tiene este atributo"
                  when has(:edad, 8)
                    "Alumno tiene 8 años"
                  when _
                    "Matcheo con _"
                end
        valor
      end
      expect(resultado).to eq("Alumno tiene 8 años")
    end

    it 'case_classes y case_objects funcionan como patrones' do
      resultado = CCContext.ejecutar do
        case_class Alumno do
          attr_accessor :nombre, :edad

          def initialize(nombre, edad)
            @nombre = nombre
            @edad = edad
          end
        end
        case_class Termino do
          attr_accessor :nota

          def initialize(nota)
            @nota = nota
          end
        end
        alumno = Alumno("Jose", Termino(9))
        valor = case alumno
                  when Alumno("Jose", Termino(7))
                    "Alumno termino con 7"
                  when Alumno("Jose", Aprobo)
                    "Estado aprobado"
                  when Alumno(_, has(:nota, 9))
                    "Alumno termino con 9"
                  when _
                    "Matcheo con _"
                end
        valor
      end
      expect(resultado).to eq("Alumno termino con 9")
    end
    it 'el retorno de copiar un case_object es la misma instancia a la que se le pidio copia' do
      resultado = CCContext.ejecutar do
        case_object UnCaseObject do

        end
        copia = UnCaseObject.copy
        [UnCaseObject, copia]
      end
      expect(resultado[0]).to equal?(resultado[1])
    end
  end
end

