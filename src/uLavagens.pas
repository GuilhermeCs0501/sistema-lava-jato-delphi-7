unit uLavagens;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DBGrids, DB, ADODB, Grids, jpeg;

type
  TfrmLavagens = class(TForm)
    pnlTitulo: TPanel;
    lblTitulo: TLabel;
    pnlCampos: TPanel;
    lblData: TLabel;
    lblCliente: TLabel;
    lblPlaca: TLabel;
    lblServico: TLabel;
    lblValor: TLabel;
    edtData: TEdit;
    edtCliente: TEdit;
    edtPlaca: TEdit;
    cbServico: TComboBox;
    edtValor: TEdit;
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
  frmLavagens: TfrmLavagens;

implementation

uses uDM;

{$R *.dfm}

{ Vincula o Grid aos dados, carregando os tipos de serviço disponíveis e inicializando
  as variáveis de controle }
procedure TfrmLavagens.FormCreate(Sender: TObject);
begin
  DBGrid1.DataSource := dmLavaJato.dsLavagens;
  DBGrid1.ReadOnly   := True;
  cbServico.Items.Add('Lavagem Simples');
  cbServico.Items.Add('Lavagem Completa');
  cbServico.Items.Add('Lavagem Detalhada');
  cbServico.Items.Add('Polimento');
  cbServico.ItemIndex := 0;
  FIdSelecionado := 0;
  FNovo := False;
  LimparCampos;
  HabilitarCampos(False);
end;

{ Atualiza os registros exibidos sempre que a tela é aberta }
procedure TfrmLavagens.FormShow(Sender: TObject);
begin
  dmLavaJato.AbrirLavagens;
  LimparCampos;
end;

{ Limpa os campos do formulário e retorna ao estado inicial }
procedure TfrmLavagens.LimparCampos;
begin
  edtData.Text    := DateToStr(Date);
  edtCliente.Text := '';
  edtPlaca.Text   := '';
  edtValor.Text   := '';
  cbServico.ItemIndex := 0;
  FIdSelecionado := 0;
  FNovo := False;
  AtualizarBotoes(False);
  HabilitarCampos(False);
end;

{ Carrega os dados da lavagem selecionada no Grid para os campos de edição }
procedure TfrmLavagens.CarregarRegistro;
begin
  if dmLavaJato.qryLavagens.IsEmpty then Exit;
  FIdSelecionado  := dmLavaJato.qryLavagens.FieldByName('Id').AsInteger;
  edtData.Text    := dmLavaJato.qryLavagens.FieldByName('Data').AsString;
  edtCliente.Text := dmLavaJato.qryLavagens.FieldByName('Cliente').AsString;
  edtPlaca.Text   := dmLavaJato.qryLavagens.FieldByName('Placa').AsString;
  cbServico.Text  := dmLavaJato.qryLavagens.FieldByName('Servico').AsString;
  edtValor.Text   := FloatToStrF(dmLavaJato.qryLavagens.FieldByName('Valor').AsFloat, ffFixed, 10, 2);
  AtualizarBotoes(False);
end;

{ Controla quais botões permanecem habilitados durante inclusão, edição ou consulta }
procedure TfrmLavagens.AtualizarBotoes(Editando: Boolean);
begin
  btnNovo.Enabled     := not Editando;
  btnEditar.Enabled   := (not Editando) and (FIdSelecionado > 0);
  btnSalvar.Enabled   := Editando;
  btnCancelar.Enabled := Editando;
  btnExcluir.Enabled  := (not Editando) and (FIdSelecionado > 0);

  DBGrid1.Enabled := not Editando;
end;

{ Prepara a tela para o cadastro de uma nova lavagem }
procedure TfrmLavagens.btnNovoClick(Sender: TObject);
begin
  LimparCampos;
  FNovo := True;
  AtualizarBotoes(True);
  HabilitarCampos(True);
  edtCliente.SetFocus;
end;

{ Habilita ou desabilita os campos para edição dos dados }
procedure TfrmLavagens.HabilitarCampos(Habilita: Boolean);
begin
  edtData.Enabled     := Habilita;
  edtCliente.Enabled  := Habilita;
  edtPlaca.Enabled    := Habilita;
  cbServico.Enabled   := Habilita;
  edtValor.Enabled    := Habilita;
end;

{ Valida os dados informados e realiza a inclusão ou alteração da lavagem no banco de dados }
procedure TfrmLavagens.btnSalvarClick(Sender: TObject);
var
  qry: TADOQuery;
  dValor: Double;
  dData: TDateTime;
  sValor: string;
begin
  // Validação do nome do cliente
  if Trim(edtCliente.Text) = '' then
  begin
    ShowMessage('Informe o nome do cliente.');
    edtCliente.SetFocus;
    Exit;
  end;

  // Validação da placa do veículo
  if Trim(edtPlaca.Text) = '' then
  begin
    ShowMessage('Informe a placa do veículo.');
    edtPlaca.SetFocus;
    Exit;
  end;

  // Validação e conversão da data informada
  try
    dData := StrToDate(Trim(edtData.Text));
  except
    on E: Exception do
    begin
      ShowMessage('Data inválida. Use o formato DD/MM/AAAA.');
      edtData.SetFocus;
      Exit;
    end;
  end;

  // Validação do valor da lavagem
  if Trim(edtValor.Text) = '' then
  begin
    ShowMessage('Informe o valor da lavagem.');
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

  qry := TADOQuery.Create(nil);
  // Define se será executado INSERT ou UPDATE
  try
    qry.Connection := dmLavaJato.ADOConnection;

    if FNovo then
    begin
      qry.SQL.Text :=
        'INSERT INTO Lavagens ' +
        '(DataLavagem, Cliente, Placa, Servico, Valor) ' +
        'VALUES ' +
        '(:DataLavagem, :Cliente, :Placa, :Servico, :Valor)';
    end
    else
    begin
      qry.SQL.Text :=
        'UPDATE Lavagens SET ' +
        'DataLavagem = :DataLavagem, ' +
        'Cliente = :Cliente, ' +
        'Placa = :Placa, ' +
        'Servico = :Servico, ' +
        'Valor = :Valor ' +
        'WHERE Id = :Id';

      qry.Parameters.ParamByName('Id').Value := FIdSelecionado;
    end;
    // Preenche os parâmetros do comando SQL
    // Executa a gravação no banco de dados

    qry.Parameters.ParamByName('DataLavagem').Value := dData;
    qry.Parameters.ParamByName('Cliente').Value :=
      Trim(edtCliente.Text);

    // Converte a placa para letras maiúsculas antes de salvar
    qry.Parameters.ParamByName('Placa').Value :=
      UpperCase(Trim(edtPlaca.Text));

    qry.Parameters.ParamByName('Servico').Value :=
      Trim(cbServico.Text);

    qry.Parameters.ParamByName('Valor').Value := dValor;

    qry.ExecSQL;

    ShowMessage('Registro salvo com sucesso!');

    dmLavaJato.AbrirLavagens;
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
procedure TfrmLavagens.btnCancelarClick(Sender: TObject);
begin
  LimparCampos;
end;

{ Exclui a lavagem selecionada após confirmação do usuário }
procedure TfrmLavagens.btnExcluirClick(Sender: TObject);
var
  qry: TADOQuery;
begin
  if FIdSelecionado <= 0 then Exit;
  if MessageDlg('Deseja excluir este registro?', mtConfirmation,
     [mbYes, mbNo], 0) <> mrYes then Exit;
  qry := TADOQuery.Create(nil);
  try
    qry.Connection := dmLavaJato.ADOConnection;
    qry.SQL.Text   := 'DELETE FROM Lavagens WHERE Id = :Id';
    qry.Parameters.ParamByName('Id').Value := FIdSelecionado;
    qry.ExecSQL;
  finally
    qry.Free;
  end;
  ShowMessage('Registro exclu'#237'do com sucesso!');
  dmLavaJato.AbrirLavagens;
  LimparCampos;
end;

{ Ao selecionar um registro no Grid, seus dados são carregados para os campos de edição }
procedure TfrmLavagens.DBGrid1CellClick(Column: TColumn);
begin
  CarregarRegistro;
end;

{ Fecha a tela e retorna ao menu principal }
procedure TfrmLavagens.btnVoltarClick(Sender: TObject);
begin
    Close;
end;

{ Habilita a edição da lavagem selecionada }
procedure TfrmLavagens.btnEditarClick(Sender: TObject);
begin
    if FIdSelecionado = 0 then
  begin
    ShowMessage('Selecione um registro.');
    Exit;
  end;

  FNovo := False;

  HabilitarCampos(True);
  AtualizarBotoes(True);

  edtCliente.SetFocus;
end;

end.
