# 🛡️ Sophira Keeper
> Gestão inteligente e segura de ativos digitais e credenciais.

O **Sophira Keeper** é uma agenda de gerenciamento de senhas da Sophira, projetado para oferecer uma camada robusta de proteção, geração e organização de dados sensíveis. Com foco em privacidade e usabilidade, o Keeper garante que o controle das informações esteja sempre nas mãos do usuário.

---

## 🚀 Versão Atual: `RELEASE 26.02.27.0`

Esta release marca o lançamento funcional da arquitetura base do sistema, entregando as ferramentas essenciais para gestão de contas e segurança.

### ✨ Funcionalidades Principais

* **🔑 Gerador de Senhas de Alta Entropia:** Crie senhas complexas e seguras com parâmetros customizáveis (tamanho, símbolos, números).
* **👤 Sistema de Autenticação:** Módulos de Cadastro e Login funcionais com persistência de sessão segura.
* **🏢 Agência de Contas:** Centralização e organização de múltiplas credenciais em uma interface intuitiva.
* **💾 CRUD de Registros:** Ciclo completo de gerenciamento (Criação, Leitura, Atualização e Exclusão) para dados de usuário.

---

## 🛠️ Tecnologias Utilizadas

O **Sophira Keeper** utiliza uma stack moderna para garantir performance multiplataforma e integridade de dados:

* **Framework:** [Flutter](https://flutter.dev/) - Interface nativa, fluida e responsiva.
* **Linguagem:** [Dart](https://dart.dev/) - Lógica de negócio com tipagem forte e alto desempenho.
* **Banco de Dados:** [MySQL](https://www.mysql.com/) - Armazenamento relacional robusto e consistente.
* **Segurança:** * Criptografia de ponta a ponta nos registros.
    * Hashing de senhas para proteção de credenciais.
    * Sanitização de inputs para prevenção de SQL Injection.

---

🛡️ Segurança e Privacidade
O Sophira Keeper foi construído sob o princípio de Privacy by Design. Nenhum dado sensível é armazenado em texto puro. Todas as interações com o banco de dados passam por camadas de sanitização e criptografia.
