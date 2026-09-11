unit uCustoVariavel;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DBGrids, DB, ADODB, Grids, jpeg;

type
  TfrmCustoVariavel = class(TForm)
    pnlTitulo: TPanel;
    lblTitulo: TLabel;
    pnlCampos: TPanel;
    lblDescricao: TLabel;
    lblValorUnitario: TLabel;
    lblMesAno: TLabel;
    edtDescricao: TEdit;
    edtValorUnitario: TEdit;
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
  frmCustoVariavel: TfrmCustoVariavel;

implementation

uses uDM;

{$R *.dfm}

{ Vincula o Grid aos dados e inicializando as variáveis de controle }
procedure TfrmCustoVariavel.FormCreate(Sender: TObject);
begin
  DBGrid1.DataSource := dmLavaJato.dsCustoVariavel;
  DBGrid1.ReadOnly   := True;
  FIdSelecionado := 0;
  FNovo := False;
  LimparCampos;

  HabilitarCampos(False);
end;

{ Atualiza os dados exibidos sempre que a tela é aberta }
procedure TfrmCustoVariavel.FormShow(Sender: TObject);
begin
  dmLavaJato.AbrirCustoVariavel;
  LimparCampos;
end;

{ Limpa os campos da tela e retorna ao estado inicial }
procedure TfrmCustoVariavel.LimparCampos;
begin
  edtDescricao.Text     := '';
  edtValorUnitario.Text := '';
  edtMesAno.Text        := FormatDateTime('mm/yyyy', Date);
  FIdSelecionado := 0;
  FNovo := False;
  HabilitarCampos(False);
  AtualizarBotoes(False);
end;

{ Carrega os dados do registro selecionado no Grid para os campos de edição }
procedure TfrmCustoVariavel.CarregarRegistro;
begin
  if dmLavaJato.qryCustoVariavel.IsEmpty then Exit;
  FIdSelecionado        := dmLavaJato.qryCustoVariavel.FieldByName('Id').AsInteger;
  edtDescricao.Text     := dmLavaJato.qryCustoVariavel.FieldByName('Descricao').AsString;
  edtValorUnitario.Text := FloatToStrF(dmLavaJato.qryCustoVariavel.FieldByName('ValorUnitario').AsFloat, ffFixed, 10, 2);
  edtMesAno.Text        := dmLavaJato.qryCustoVariavel.FieldByName('MesAno').AsString;
  AtualizarBotoes(False);
end;

{ Controla quais botões permanecem habilitados durante inclusão, edição ou consulta }
procedure TfrmCustoVariavel.AtualizarBotoes(Editando: Boolean);
begin
  btnNovo.Enabled     := not Editando;
  btnEditar.Enabled   := (not Editando) and (FIdSelecionado > 0);
  btnSalvar.Enabled   := Editando;
  btnCancelar.Enabled := Editando;
  btnExcluir.Enabled  := (not Editando) and (FIdSelecionado > 0);

  DBGrid1.Enabled := not Editando;
end;

{ Habilita ou desabilita os campos para edição }
procedure TfrmCustoVariavel.HabilitarCampos(Habilita: Boolean);
begin
  edtDescricao.Enabled := Habilita;
  edtValorUnitario.Enabled := Habilita;
  edtMesAno.Enabled    := Habilita;
end;

{ Prepara a tela para inclusão de um novo custo variável }
procedure TfrmCustoVariavel.btnNovoClick(Sender: TObject);
begin
  LimparCampos;
  FNovo := True;

  HabilitarCampos(True);

  AtualizarBotoes(True);
  edtDescricao.SetFocus;
end;

{ Valida os dados informados e realiza a inclusão ou alteração do registro no banco de dados }
procedure TfrmCustoVariavel.btnSalvarClick(Sender: TObject);
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

  // Validação do valor unitário informado
  if Trim(edtValorUnitario.Text) = '' then
  begin
    ShowMessage('Informe o valor unitário (por lavagem).');
    edtValorUnitario.SetFocus;
    Exit;
  end;

  try
    // Conversão do valor digitado para formato numérico
    sValor := StringReplace(
      Trim(edtValorUnitario.Text),
      ',',
      DecimalSeparator,
      [rfReplaceAll]
    );

    dValor := StrToFloat(sValor);

  except
    on E: Exception do
    begin
      ShowMessage('Valor inválido. Use apenas números.');
      edtValorUnitario.SetFocus;
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

  // Define se a operação será INSERT ou UPDATE
  try
    qry.Connection := dmLavaJato.ADOConnection;

    if FNovo then
    begin
      qry.SQL.Text :=
        'INSERT INTO CustoVariavel ' +
        '(Descricao, ValorUnitario, MesAno) ' +
        'VALUES (:Descricao, :ValorUnitario, :MesAno)';
    end
    else
    begin
      qry.SQL.Text :=
        'UPDATE CustoVariavel SET ' +
        'Descricao = :Descricao, ' +
        'ValorUnitario = :ValorUnitario, ' +
        'MesAno = :MesAno ' +
        'WHERE Id = :Id';

      qry.Parameters.ParamByName('Id').Value := FIdSelecionado;
    end;
    // Executa o comando SQL no banco de dados
    qry.Parameters.ParamByName('Descricao').Value :=
      Trim(edtDescricao.Text);

    qry.Parameters.ParamByName('ValorUnitario').Value :=
      dValor;

    qry.Parameters.ParamByName('MesAno').Value :=
      Trim(edtMesAno.Text);

    qry.ExecSQL;

    ShowMessage('Registro salvo com sucesso!');

    dmLavaJato.AbrirCustoVariavel;
    LimparCampos;

  except
    on E: Exception do
    begin
      ShowMessage('Erro ao salvar registro: ' + E.Message);
    end;
  end;

  qry.Free;
end;

{ Cancela a operação atual e limpa os campos }
procedure TfrmCustoVariavel.btnCancelarClick(Sender: TObject);
begin
  LimparCampos;
end;

{ Exclui o registro selecionado após confirmação do usuário }
procedure TfrmCustoVariavel.btnExcluirClick(Sender: TObject);
var
  qry: TADOQuery;
begin
  if FIdSelecionado <= 0 then Exit;
  if MessageDlg('Deseja excluir este registro?', mtConfirmation,
     [mbYes, mbNo], 0) <> mrYes then Exit;
  qry := TADOQuery.Create(nil);
  try
    qry.Connection := dmLavaJato.ADOConnection;
    qry.SQL.Text   := 'DELETE FROM CustoVariavel WHERE Id = :Id';
    qry.Parameters.ParamByName('Id').Value := FIdSelecionado;
    qry.ExecSQL;
  finally
    qry.Free;
  end;
  ShowMessage('Registro exclu'#237'do com sucesso!');
  dmLavaJato.AbrirCustoVariavel;
  LimparCampos;
end;

{ Carrega os dados do registro selecionado no Grid }
procedure TfrmCustoVariavel.DBGrid1CellClick(Column: TColumn);
begin
  CarregarRegistro;
end;

{ Fecha a tela e retorna ao menu principal }
procedure TfrmCustoVariavel.btnVoltarClick(Sender: TObject);
begin
    Close;
end;

{ Habilita a edição do registro selecionado }
procedure TfrmCustoVariavel.btnEditarClick(Sender: TObject);
begin
     if FIdSelecionado = 0 then
  begin
    ShowMessage('Selecione um registro.');
    Exit;
  end;

  FNovo := False;

  HabilitarCampos(True);

  AtualizarBotoes(True);

  edtDescricao.SetFocus;
end;

end.

