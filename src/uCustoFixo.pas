unit uCustoFixo;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DBGrids, DB, ADODB, Grids, jpeg;

type
  TfrmCustoFixo = class(TForm)
    pnlTitulo: TPanel;
    lblTitulo: TLabel;
    pnlCampos: TPanel;
    lblDescricao: TLabel;
    lblValor: TLabel;
    lblMesAno: TLabel;
    edtDescricao: TEdit;
    edtValor: TEdit;
    edtMesAno: TEdit;
    btnNovo: TButton;
    btnSalvar: TButton;
    btnCancelar: TButton;
    btnExcluir: TButton;
    DBGrid1: TDBGrid;
    btnVoltar: TButton;
    btnEditar: TButton;
    Image1: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure DBGrid1CellClick(Column: TColumn);
    procedure btnVoltarClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
  private
    FNovo: Boolean;
    FIdSelecionado: Integer;
    procedure LimparCampos;
    procedure CarregarRegistro;
    procedure AtualizarBotoes(Editando: Boolean);

    procedure HabilitarCampos(Habilita: Boolean);
  public
    { Public declarations }
  end;

var
  frmCustoFixo: TfrmCustoFixo;

implementation

uses uDM;

{$R *.dfm}

{ Vincula o Grid aos dados e inicializando variáveis de controle }
procedure TfrmCustoFixo.FormCreate(Sender: TObject);
begin
  DBGrid1.DataSource := dmLavaJato.dsCustoFixo;
  DBGrid1.ReadOnly   := True;
  FIdSelecionado := 0;
  FNovo := False;
  HabilitarCampos(False);
  LimparCampos;
end;

{ Atualiza os dados exibidos sempre que a tela é aberta }
procedure TfrmCustoFixo.FormShow(Sender: TObject);
begin
  dmLavaJato.AbrirCustoFixo;
  LimparCampos;
end;

{ Limpa os campos do formulário e retorna a tela ao estado inicial }
procedure TfrmCustoFixo.LimparCampos;
begin
  edtDescricao.Text := '';
  edtValor.Text     := '';
  edtMesAno.Text    := FormatDateTime('mm/yyyy', Date);
  FIdSelecionado := 0;
  FNovo := False;
  HabilitarCampos(False);
  AtualizarBotoes(False);
end;

{ Carrega os dados do registro selecionado no Grid para os campos de edição }
procedure TfrmCustoFixo.CarregarRegistro;
begin
  if dmLavaJato.qryCustoFixo.IsEmpty then Exit;
  FIdSelecionado    := dmLavaJato.qryCustoFixo.FieldByName('Id').AsInteger;
  edtDescricao.Text := dmLavaJato.qryCustoFixo.FieldByName('Descricao').AsString;
  edtValor.Text     := FloatToStrF(dmLavaJato.qryCustoFixo.FieldByName('Valor').AsFloat, ffFixed, 10, 2);
  edtMesAno.Text    := dmLavaJato.qryCustoFixo.FieldByName('MesAno').AsString;
  AtualizarBotoes(False);
end;

{ Controla quais botões ficam habilitados de acordo com o estado da tela (edição ou consulta) }
procedure TfrmCustoFixo.AtualizarBotoes(Editando: Boolean);
begin
  btnNovo.Enabled     := not Editando;
  btnEditar.Enabled   := (not Editando) and (FIdSelecionado > 0);
  btnSalvar.Enabled   := Editando;
  btnCancelar.Enabled := Editando;
  btnExcluir.Enabled  := (not Editando) and (FIdSelecionado > 0);

  DBGrid1.Enabled := not Editando;
end;

{ Habilita ou desabilita os campos de entrada de dados }
procedure TfrmCustoFixo.HabilitarCampos(Habilita: Boolean);
begin
  edtDescricao.Enabled := Habilita;
  edtValor.Enabled     := Habilita;
  edtMesAno.Enabled    := Habilita;
end;

{ Prepara a tela para inclusão de um novo custo fixo }
procedure TfrmCustoFixo.btnNovoClick(Sender: TObject);
begin
  LimparCampos;
  FNovo := True;

  HabilitarCampos(True);

  AtualizarBotoes(True);
  edtDescricao.SetFocus;
end;

{ Realiza as validações dos dados informados e executa a inclusão ou alteração do registro no banco de dados }
procedure TfrmCustoFixo.btnSalvarClick(Sender: TObject);
var
  qry: TADOQuery;
  dValor: Double;
  sValor: string;
begin
  // Validação da descrição do custo
  if Trim(edtDescricao.Text) = '' then
  begin
    ShowMessage('Informe a descrição do custo.');
    edtDescricao.SetFocus;
    Exit;
  end;

  // Validação do valor informado
  if Trim(edtValor.Text) = '' then
  begin
    ShowMessage('Informe o valor.');
    edtValor.SetFocus;
    Exit;
  end;

  try
    // Conversão do valor digitado para formato numérico
    sValor := StringReplace(
      Trim(edtValor.Text),
      ',',
      DecimalSeparator,
      [rfReplaceAll]
    );

    dValor := StrToFloat(sValor);

  except
    on E: Exception do
    begin
      ShowMessage('Valor inválido. Use apenas números.');
      edtValor.SetFocus;
      Exit;
    end;
  end;

  // Validação do campo mês/ano
  if Length(Trim(edtMesAno.Text)) <> 7 then
  begin
    ShowMessage('Informe o mês/ano no formato MM/AAAA. Ex: 05/2026');
    edtMesAno.SetFocus;
    Exit;
  end;

  qry := TADOQuery.Create(nil);
      // Define se será executado INSERT ou UPDATE
  try
    qry.Connection := dmLavaJato.ADOConnection;

    if FNovo then
    begin
      qry.SQL.Text :=
        'INSERT INTO CustoFixo ' +
        '(Descricao, Valor, MesAno) ' +
        'VALUES (:Descricao, :Valor, :MesAno)';
    end
    else
    begin
      qry.SQL.Text :=
        'UPDATE CustoFixo SET ' +
        'Descricao = :Descricao, ' +
        'Valor = :Valor, ' +
        'MesAno = :MesAno ' +
        'WHERE Id = :Id';

      qry.Parameters.ParamByName('Id').Value := FIdSelecionado;
    end;
    
    // Executa o comando SQL no banco de dados

    qry.Parameters.ParamByName('Descricao').Value :=
      Trim(edtDescricao.Text);

    qry.Parameters.ParamByName('Valor').Value :=
      dValor;

    qry.Parameters.ParamByName('MesAno').Value :=
      Trim(edtMesAno.Text);

    qry.ExecSQL;

    ShowMessage('Registro salvo com sucesso!');

    dmLavaJato.AbrirCustoFixo;
    LimparCampos;

  except
    on E: Exception do
    begin
      ShowMessage('Erro ao salvar registro: ' + E.Message);
    end;
  end;

  qry.Free;
end;

{ Cancela a operação atual e limpa os campos da tela }
procedure TfrmCustoFixo.btnCancelarClick(Sender: TObject);
begin
  LimparCampos;
end;

{ Exclui o registro selecionado após confirmação do usuário }
procedure TfrmCustoFixo.btnExcluirClick(Sender: TObject);
var
  qry: TADOQuery;
begin
  if FIdSelecionado <= 0 then Exit;
  if MessageDlg('Deseja excluir este registro?', mtConfirmation,
     [mbYes, mbNo], 0) <> mrYes then Exit;
  qry := TADOQuery.Create(nil);
  try
    qry.Connection := dmLavaJato.ADOConnection;
    qry.SQL.Text   := 'DELETE FROM CustoFixo WHERE Id = :Id';
    qry.Parameters.ParamByName('Id').Value := FIdSelecionado;
    qry.ExecSQL;
  finally
    qry.Free;
  end;
  ShowMessage('Registro exclu'#237'do com sucesso!');
  dmLavaJato.AbrirCustoFixo;
  LimparCampos;
end;

{ Ao selecionar um registro no Grid, carrega seus dados para os campos de edição }
procedure TfrmCustoFixo.DBGrid1CellClick(Column: TColumn);
begin
  CarregarRegistro;
end;

{ Fecha a tela e retorna ao menu principal }
procedure TfrmCustoFixo.btnVoltarClick(Sender: TObject);
begin
    Close;
end;

{ Habilita a edição do registro selecionado }
procedure TfrmCustoFixo.btnEditarClick(Sender: TObject);
begin
      if FIdSelecionado = 0 then
  begin
    ShowMessage('Selecione um registro no Grid.');
    Exit;
  end;

  FNovo := False;

  HabilitarCampos(True);

  AtualizarBotoes(True);

  edtDescricao.SetFocus;
end;

end.


