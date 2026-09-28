# Convenções de estrutura de projeto

*Referência da skill `mapperidea` — carregada sob demanda. Volte ao `SKILL.md` para o roteiro.*

## Convenções de Estrutura de Projeto

### Estrutura de arquivos e pastas

```
projeto/
├── main.mi                        ← Mapa principal (raiz do pacote da empresa)
├── domain/
│   ├── pessoa/
│   │   ├── Pessoa.mi
│   │   └── Endereco.mi
│   ├── produto/
│   │   └── Produto.mi
│   └── financeiro/
│       └── Pedido.mi
└── generators/
    ├── quarkus/
    │   ├── quarkus-domain.mi
    │   ├── quarkus-entity.mi
    │   ├── quarkus-builder.mi
    │   ├── quarkus-mapper.mi
    │   └── quarkus-resource.mi
    └── swagger/
        └── swagger-restAPI.mi
```

- **Mapa principal** (`main.mi`) fica na raiz — contém o `[p]` raiz, o bloco `config`, e as referências `#` para os demais arquivos
- **Domínios** ficam em subpastas espelhando a hierarquia de pacotes (`domain/pessoa/Pessoa.mi`)
- **Geradores** ficam em `generators/` organizados por framework/linguagem quando há muitos; diretamente em `generators/` quando há poucos
- **Nomes de arquivos** de classes usam PascalCase (`Pessoa.mi`); geradores usam kebab-case prefixado pelo stack (`quarkus-domain.mi`, `swagger-restAPI.mi`)

### Referências entre arquivos (`#`)

Links entre mapas usam **caminhos relativos**. No topo do arquivo de domínio ou gerador, declare a referência ao mapa principal:

```
[e] domain
    #
        ../main.mi
    [e] parameters
        ...
```

O `#` com o caminho aponta para o arquivo `.mm` (formato FreeMind) ou `.mi` que contém a fonte de dados do gerador. Mas também podemos apontar para arquivos .xml e .json. Que podem ser usados como formato extra pela maquina de inferencia.

---
