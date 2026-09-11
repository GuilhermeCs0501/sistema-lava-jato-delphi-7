program Project1;

uses
  Forms,
  uDM in 'uDM.pas' {dmLavaJato: TDataModule},
  uPrincipal in 'uPrincipal.pas' {frmPrincipal},
  uLavagens in 'uLavagens.pas' {frmLavagens},
  uCustoFixo in 'uCustoFixo.pas' {frmCustoFixo},
  uCustoVariavel in 'uCustoVariavel.pas' {frmCustoVariavel},
  uFinanceiro in 'uFinanceiro.pas' {frmFinanceiro},
  uHistorico in 'uHistorico.pas' {frmHistorico},
  uRelatorioCusto in 'uRelatorioCusto.pas' {frmRelatorioCusto};

{$R *.res}

begin
  Application.Initialize;
  { Data Module criado primeiro para estar disponivel a todos os forms }
  Application.CreateForm(TdmLavaJato, dmLavaJato);
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.CreateForm(TfrmLavagens, frmLavagens);
  Application.CreateForm(TfrmCustoFixo, frmCustoFixo);
  Application.CreateForm(TfrmCustoVariavel, frmCustoVariavel);
  Application.CreateForm(TfrmFinanceiro, frmFinanceiro);
  Application.CreateForm(TfrmHistorico, frmHistorico);
  Application.CreateForm(TfrmRelatorioCusto, frmRelatorioCusto);
  Application.Run;
end.
