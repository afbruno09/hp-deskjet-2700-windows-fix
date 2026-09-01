# Segurança e privacidade

Os scripts de reparo e limpeza podem exigir privilégios administrativos.

Antes de abrir uma issue ou compartilhar um relatório:

1. remova nomes de usuário e computador;
2. substitua endereços IP por valores fictícios;
3. remova números de série, UUIDs e endereços MAC;
4. não anexe backups `.reg`;
5. não publique logs CBS ou DISM completos sem revisão.

O script `limpar-filas-hp.ps1` cria um backup antes de alterar registros e usa confirmação de alto impacto. Ainda assim, revise o padrão informado para evitar remover filas que não fazem parte do problema.

Relate vulnerabilidades de forma privada ao mantenedor do repositório, quando houver um canal de contato definido.
