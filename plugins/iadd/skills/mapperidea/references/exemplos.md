# Exemplos completos

*Referência da skill `mapperidea` — carregada sob demanda. Volte ao `SKILL.md` para o roteiro.*

## Exemplo Completo: Mapa de Negócios

```
[p] domain
    [p] pessoa
        [b] PessoaFisica
            [g] atributos
                [d] nome: Texto(128)
                    @
                        [e] description
                            [v] Nome completo da pessoa
                            [v] Usar o nome que consta em documentos oficiais
                [d] cpf: Inteiro(11)
                    @
                        [e] description
                            [v] Número do CPF sem formatação
                [d] dataNascimento: Data()
                [d] ativo: Boolean()
                [r] naturalidade: Cidade()
                [o] enderecos: Endereco()
            [g] métodos
                [x] calculaIdade: Inteiro(2)
                    body
                        if
                            condition
                                self.dataNascimento
                            then
                                return
                                    FuncoesTempo.diferencaAnos()
                                        self.dataNascimento
                                        DataHoje()
                            else
                                return
                                    -1
        [b] Endereco
            [g] atributos
                [d] logradouro: Texto(200)
                [d] cep: Texto(8)
                [m] pessoaFisica: PessoaFisica()
```

## Exemplo Completo: Trecho de Mapa de Arquitetura (gerador SQL)

```
[p] com.example
    config
        [e] mapperidea
            [e] maps
                [e] toSqlTypes
                    [e] Texto
                        [v] VARCHAR
                    [e] TextoLongo
                        [v] TEXT
                    [e] Inteiro
                        [v] INT
                    [e] Data
                        [v] DATE
                    [e] DataHora
                        [v] TIMESTAMP
                    [e] Boolean
                        [v] BOOLEAN
            [e] generators
                [e] createTable
                    [e] parameters
                        [e] className
                            [v] NOT_DEFINED
                    [e] vars
                        [e] toSqlTypes
                            [e] select
                                [v] //maps/toSqlTypes
                    [e] start
                        [e] match
                            [v] classes/class[@name=$className]
                        [e] body
                            [e] write-pattern
                                [v] declaraTabela
                            [e] apply-templates
                                [e] select
                                    [v] attributes/attribute[@mode='directToField']
                                [e] mode
                                    [v] declaraColunas
                            [e] write-pattern
                                [v] fechaTabela
                    [e] patterns
                        [e] declaraTabela
                            [v] CREATE TABLE {{ mi:lower-case-add-underline(@name,'') }} (
                            [v]     id SERIAL NOT NULL,
                        [e] fechaTabela
                            [v]     PRIMARY KEY (id)
                            [v] );
                    [e] templates
                        [e] mode
                            [v] declaraColunas
                            [e] template
                                [e] match
                                    [v] attribute[@type = $toSqlTypes/Texto]
                                [e] body
                                    [e] write-pattern
                                        [v] colunaTipoTexto
                            [e] template
                                [e] match
                                    [v] attribute[@type = $toSqlTypes/Data]
                                [e] body
                                    [e] write-pattern
                                        [v] colunaTipoData
                    [e] patterns
                        [e] colunaTipoTexto
                            [v]     {{ mi:lower-case-add-underline(@name,'') }} VARCHAR({{ @typeParameter }}),
                        [e] colunaTipoData
                            [v]     {{ mi:lower-case-add-underline(@name,'') }} DATE,
```
