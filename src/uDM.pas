unit uDM;

interface

uses
  SysUtils, Classes, ADODB, DB, Dialogs;

type
  TdmLavaJato = class(TDataModule)
    ADOConnection: TADOConnection;
    qryLavagens: TADOQuery;
    dsLavagens: TDataSource;
    qryCustoFixo: TADOQuery;
    dsCustoFixo: TDataSource;
    qryCustoVariavel: TADOQuery;
    dsCustoVariavel: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    procedure AbrirLavagens;
    procedure AbrirCustoFixo;
    procedure AbrirCustoVariavel;
  end;

var
  dmLavaJato: TdmLavaJato;

implementation

{$R *.dfm}

// DataModule responsável por centralizar a conexão com o banco de dados
// e disponibilizar as consultas utilizadas pelo sistema
procedure TdmLavaJato.DataModuleCreate(Sender: TObject);
begin
  try
  // Abre a conexão com o SQL Server
    ADOConnection.Open;

    // Carrega os dados iniciais
    AbrirLavagens;
    AbrirCustoFixo;
    AbrirCustoVariavel;

    // Exibe uma mensagem caso ocorra erro na conexão
  except
    on E: Exception do
      ShowMessage('Erro ao conectar ao banco de dados.' + #13#10 +
                  'Verifique a connection string em uDM.dfm.' + #13#10 + E.Message);
  end;
end;

// Atualiza a consulta de lavagens
// Recupera todas as lavagens cadastradas ordenadas
// da mais recente para a mais antiga
procedure TdmLavaJato.AbrirLavagens;
begin
  qryLavagens.Close;
  qryLavagens.SQL.Text :=
    'SELECT Id, CONVERT(varchar(10), DataLavagem, 103) AS Data, ' +
    'Cliente, Placa, Servico, Valor ' +
    'FROM Lavagens ORDER BY DataLavagem DESC, Id DESC';
  qryLavagens.Open;
end;

// Atualiza a consulta dos custos fixos
// Exibe os registros organizados por mês/ano
procedure TdmLavaJato.AbrirCustoFixo;
begin
  qryCustoFixo.Close;
  qryCustoFixo.SQL.Text := 'SELECT * FROM CustoFixo ORDER BY MesAno DESC, Id';
  qryCustoFixo.Open;
end;

// Atualiza a consulta dos custos variáveis
// Exibe os registros organizados por mês/ano
procedure TdmLavaJato.AbrirCustoVariavel;
begin
  qryCustoVariavel.Close;
  qryCustoVariavel.SQL.Text := 'SELECT * FROM CustoVariavel ORDER BY MesAno DESC, Id';
  qryCustoVariavel.Open;
end;

end.
