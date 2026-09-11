unit uRelatorioCusto;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Grids, ADODB, jpeg;

type
  TfrmRelatorioCusto = class(TForm)
    pnlTitulo: TPanel;
    lblTitulo: TLabel;
    pnlFiltro: TPanel;
    lblMesAno: TLabel;
    edtMesAno: TEdit;
    btnAtualizar: TButton;
    pnlCorpo: TPanel;
    pnlCF: TPanel;
    lblTituloCF: TLabel;
    sgCF: TStringGrid;
    pnlTotalCF: TPanel;
    lblTotalCF: TLabel;
    lblVTotalCF: TLabel;
    pnlCVU: TPanel;
    lblTituloCVU: TLabel;
    sgCVU: TStringGrid;
    pnlTotalCVU: TPanel;
    lblTotalCVU: TLabel;
    lblVTotalCVU: TLabel;
    pnlBottom: TPanel;
    lblCT: TLabel;    lblVCT: TLabel;
    lblMCU: TLabel;   lblVMCU: TLabel;
    lblPE: TLabel;    lblVPE: TLabel;
    Button1: TButton;
    Image1: TImage;
    procedure FormShow(Sender: TObject);
    procedure btnAtualizarClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    procedure Atualizar;
    procedure LimparGrids;
  public
    { Public declarations }
  end;

var
  frmRelatorioCusto: TfrmRelatorioCusto;

implementation

uses uDM;

{$R *.dfm}

// Executado ao abrir a tela
// Preenche automaticamente o campo Mês/Ano com o mês atual
// e limpa os dados exibidos nas grades
procedure TfrmRelatorioCusto.FormShow(Sender: TObject);
begin
  edtMesAno.Text := FormatDateTime('mm/yyyy', Date);
  LimparGrids;
end;

// Limpa as grids de Custos Fixos e Custos Variáveis,
// recriando os cabeçalhos e zerando os indicadores
procedure TfrmRelatorioCusto.LimparGrids;
begin
  sgCF.RowCount  := 2;
  sgCF.Cells[0, 0] := 'Descri'#231#227'o';
  sgCF.Cells[1, 0] := 'Valor (R$)';
  sgCF.Cells[0, 1] := '';
  sgCF.Cells[1, 1] := '';

  sgCVU.RowCount  := 2;
  sgCVU.Cells[0, 0] := 'Descri'#231#227'o';
  sgCVU.Cells[1, 0] := 'Vlr/carro (R$)';
  sgCVU.Cells[0, 1] := '';
  sgCVU.Cells[1, 1] := '';

  lblVTotalCF.Caption  := 'R$ 0,00';
  lblVTotalCVU.Caption := 'R$ 0,00';
  lblVCT.Caption       := '-';
  lblVMCU.Caption      := '-';
  lblVPE.Caption       := '-';
end;

// Evento do botão Atualizar
// Executa a consulta e recalcula todos os indicadores
procedure TfrmRelatorioCusto.btnAtualizarClick(Sender: TObject);
begin
  Atualizar;
end;

// Responsável por carregar os custos do mês informado
// e calcular os indicadores financeiros
procedure TfrmRelatorioCusto.Atualizar;
var
  qry: TADOQuery;
  sMesAno: string;
  iMes, iAno, iRow: Integer;
  totalCF, totalCVU, CT, MCU, PE: Double;
  Q: Integer;
begin
// Obtém o mês/ano digitado pelo usuário
  sMesAno := Trim(edtMesAno.Text);
// Valida se o campo está no formato MM/AAAA
  if Length(sMesAno) <> 7 then
  begin
    ShowMessage('Informe o m'#234's/ano no formato MM/AAAA. Ex: 05/2026');
    edtMesAno.SetFocus;
    Exit;
  end;
  try
  // Extrai o mês e o ano para utilização nas consultas SQL
    iMes := StrToInt(Copy(sMesAno, 1, 2));
    iAno := StrToInt(Copy(sMesAno, 4, 4));
  except
    ShowMessage('M'#234's/Ano inv'#225'lido.');
    Exit;
  end;

  LimparGrids;
  totalCF  := 0;
  totalCVU := 0;

  qry := TADOQuery.Create(nil);
  try
    qry.Connection := dmLavaJato.ADOConnection;

    { Itens de Custo Fixo }
    qry.SQL.Text :=
      'SELECT Descricao, Valor FROM CustoFixo WHERE MesAno = :MesAno ORDER BY Id';
    qry.Parameters.ParamByName('MesAno').Value := sMesAno;
    qry.Open;
    iRow := 1;
    while not qry.Eof do
    // Preenche a grid com cada item encontrado
    // e acumula o valor total dos custos fixos.
    begin
      sgCF.RowCount := iRow + 1;
      sgCF.Cells[0, iRow] := qry.FieldByName('Descricao').AsString;
      sgCF.Cells[1, iRow] := FloatToStrF(qry.FieldByName('Valor').AsFloat, ffFixed, 10, 2);
      totalCF := totalCF + qry.FieldByName('Valor').AsFloat;
      qry.Next;
      Inc(iRow);
    end;
    qry.Close;
    lblVTotalCF.Caption := 'R$ ' + FloatToStrF(totalCF, ffFixed, 10, 2);

    { Itens de Custo Variavel Unitario }
    qry.SQL.Text :=
      'SELECT Descricao, ValorUnitario FROM CustoVariavel WHERE MesAno = :MesAno ORDER BY Id';
    qry.Parameters.ParamByName('MesAno').Value := sMesAno;
    qry.Open;
    iRow := 1;
    while not qry.Eof do
    begin
      sgCVU.RowCount := iRow + 1;
      sgCVU.Cells[0, iRow] := qry.FieldByName('Descricao').AsString;
      sgCVU.Cells[1, iRow] := FloatToStrF(qry.FieldByName('ValorUnitario').AsFloat, ffFixed, 10, 2);
      totalCVU := totalCVU + qry.FieldByName('ValorUnitario').AsFloat;
      qry.Next;
      Inc(iRow);
    end;
    qry.Close;
    lblVTotalCVU.Caption := 'R$ ' + FloatToStrF(totalCVU, ffFixed, 10, 2) + '/carro';

    { Quantidade de lavagens do mes para calcular CT }
    qry.SQL.Text :=
      'SELECT COUNT(*) AS Q, ISNULL(SUM(Valor), 0) AS R FROM Lavagens ' +
      'WHERE MONTH(DataLavagem) = :Mes AND YEAR(DataLavagem) = :Ano';
    qry.Parameters.ParamByName('Mes').Value := iMes;
    qry.Parameters.ParamByName('Ano').Value := iAno;
    qry.Open;
    Q  := qry.FieldByName('Q').AsInteger;
    qry.Close;

    CT := totalCF + (totalCVU * Q);
    lblVCT.Caption := 'R$ ' + FloatToStrF(CT, ffFixed, 10, 2);

    { MCU e PE precisam do PV medio }
    if Q > 0 then
    begin
      qry.SQL.Text :=
        'SELECT ISNULL(SUM(Valor),0) AS R FROM Lavagens ' +
        'WHERE MONTH(DataLavagem) = :Mes AND YEAR(DataLavagem) = :Ano';
      qry.Parameters.ParamByName('Mes').Value := iMes;
      qry.Parameters.ParamByName('Ano').Value := iAno;
      qry.Open;
      MCU := (qry.FieldByName('R').AsFloat / Q) - totalCVU;
      qry.Close;
      lblVMCU.Caption := 'R$ ' + FloatToStrF(MCU, ffFixed, 10, 2) + '/carro';
      if MCU > 0 then
      begin
        PE := totalCF / MCU;
        lblVPE.Caption := FloatToStrF(PE, ffFixed, 10, 2) + ' carros';
      end else
        lblVPE.Caption := 'MCU <= 0';
    end else
    begin
    // Caso não existam lavagens no período,
    // não é possível calcular MCU e PE
      lblVMCU.Caption := 'Sem lavagens';
      lblVPE.Caption  := 'Sem lavagens';
    end;

  finally
    qry.Free;
  end;
end;

// Fecha a tela de relatório de custos
procedure TfrmRelatorioCusto.Button1Click(Sender: TObject);
begin
    Close;
end;

end.


