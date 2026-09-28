# O DOM em memória e a referência XPath

*Referência da skill `mapperidea` — carregada sob demanda. Volte ao `SKILL.md` para o roteiro.*

## DOM em Memória (XPath Reference)

A máquina de inferência mantém em memória:

```xml
<classes>
  <class name="PessoaFisica" mode="bean" package="domain.pessoa">
    <attributes>
      <attribute name="nome" mode="directToField" type="Texto" typeParameter="128">
        <properties>
          <description>
            <value>Nome completo da pessoa</value>
          </description>
          <property name="required" value="true"/>
        </properties>
      </attribute>
      <attribute name="naturalidade" mode="oneToOne" type="Cidade" typeParameter=""/>
      <attribute name="enderecos" mode="oneToMany" type="Endereco" typeParameter=""/>
    </attributes>
    <methods>
      <method name="calculaIdade" returnType="Inteiro" mode="public">
        <parameters/>
        <body>...</body>
      </method>
    </methods>
  </class>
</classes>
```

**XPaths úteis:**
- `classes/class` — todas as classes
- `classes/class[@name='PessoaFisica']` — classe específica
- `attributes/attribute[@mode='directToField']` — atributos simples
- `attributes/attribute[@mode='oneToMany']` — coleções
- `attributes/attribute[@type='Texto']` — por tipo específico
- `attributes/attribute[@type = $mapNativeTypes/String/value]` — por família de tipos
- `properties/description/value` — valor de descrição (Modo 1)
- `properties/property[@name='required']/@value` — propriedade chave-valor (Modo 2)
- `//maps/mapNativeTypes` — acesso ao config de tipos

---
