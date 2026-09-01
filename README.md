# HP DeskJet 2700 no Windows: filas presas, duplicadas ou sem impressão física

Guia e scripts auxiliares para diagnosticar problemas em que uma HP DeskJet 2700:

- aparece como offline mesmo estando acessível na rede;
- cria várias filas WSD/IPP duplicadas;
- deixa trabalhos em `Printing` ou `Unknown status`;
- marca um trabalho como `Printed`, mas nenhuma página sai;
- faz os comandos `Get-Printer`, `Add-Printer` ou `Add-PrinterPort` travarem.

> **Aviso:** este projeto não é oficial da HP nem da Microsoft. Leia os scripts antes de executá-los. As rotinas de reparo exigem privilégios administrativos.

## O que resolveu o caso documentado

O caso que originou este projeto tinha mais de uma causa:

1. filas WSD/IPP duplicadas e registros incompletos;
2. falhas do provedor de impressão em `ROOT\StandardCimv2`, registradas pelo WMI;
3. arquivos do Windows corrompidos, posteriormente reparados pelo SFC;
4. driver genérico inadequado para uma fila RAW/TCP 9100;
5. cartucho colorido ausente e cartucho preto muito baixo;
6. necessidade de concluir a instalação pelo HP Smart após reparar o Windows.

A sequência segura foi:

1. confirmar que a impressora estava ligada e acessível;
2. verificar papel, tampa e cartuchos;
3. diagnosticar o serviço de impressão e os eventos do WMI;
4. reparar DISM, SFC e WMI quando os provedores de impressão continuavam travando;
5. reiniciar o computador;
6. instalar/abrir o HP Smart e adicionar novamente a impressora;
7. imprimir um relatório pelo próprio HP Smart.

## Antes de começar

- Reinicie a impressora e o computador.
- Confirme que computador e impressora estão na mesma rede.
- Verifique papel, tampa e cartuchos.
- Instale o [HP Smart pelo canal oficial da HP](https://www.hp.com/us-en/printers/hp-smart.html).
- Não publique relatórios de diagnóstico sem revisar nomes de usuário, IPs, seriais e caminhos locais.

## 1. Diagnóstico

Abra o PowerShell e execute:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\diagnosticar-impressora.ps1 -PrinterAddress "ENDERECO_IP_DA_IMPRESSORA"
```

O endereço é opcional. O script consulta serviços, filas, eventos recentes e conectividade sem alterar a configuração.

## 2. Reparar componentes do Windows

Use esta etapa somente quando os comandos de impressora travarem ou os eventos mostrarem falhas WMI/RPC, como `0x80041001`, `0x80041032` ou `0x800706BA`.

Abra o PowerShell **como administrador**:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\reparar-windows-impressao.ps1
```

O script executa, nesta ordem:

```text
DISM /Online /Cleanup-Image /RestoreHealth
sfc /scannow
winmgmt /salvagerepository
```

Reinicie o computador depois da conclusão.

## 3. Limpar somente filas HP selecionadas

Esta etapa é opcional. Ela cria um backup do ramo de impressoras do Registro e pede confirmação antes de remover filas correspondentes ao padrão informado.

```powershell
.\scripts\limpar-filas-hp.ps1 -PrinterPattern "HP DeskJet 2700"
```

Para também excluir trabalhos presos de **todas** as filas:

```powershell
.\scripts\limpar-filas-hp.ps1 -PrinterPattern "HP DeskJet 2700" -ClearAllPrintJobs
```

## 4. Reinstalar pelo HP Smart

Depois de reiniciar:

1. abra o HP Smart;
2. escolha **Adicionar impressora**;
3. selecione a DeskJet detectada na rede;
4. conclua a instalação do componente de suporte solicitado;
5. imprima um relatório de diagnóstico no próprio aplicativo.

## Por que a porta TCP 9100 não é a correção recomendada

A porta RAW 9100 pode aceitar bytes e fazer o Windows marcar o trabalho como `Printed`. Isso não garante que a impressora compreenda o formato gerado pelo driver. Neste caso, o `Microsoft IPP Class Driver` ligado a uma porta RAW não produziu impressão física. Prefira o fluxo IPP configurado pelo HP Smart ou um driver oficial compatível.

## Privacidade

Nunca publique:

- números de série;
- endereços IP reais;
- UUIDs de dispositivos;
- nomes, e-mails ou caminhos de perfil;
- arquivos `.reg`, logs CBS/DISM completos ou capturas sem censura.

## Licença

Distribuído sob a licença MIT. Consulte [LICENSE](LICENSE).
