#!/usr/bin/perl -w 
#cbioPortal_documents.pl

use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use File::Basename;

my $results= GetOptions (\%opt,'fpkm|f=s','logcpm|l=s','cnv|c=s','prefix|p=s','help|h');

open ENT_ENS, "</project/shared/bicf_workflow_ref/human/gene_info.human.txt" or die $!;
my %entrez;
my $ent_header = <ENT_ENS>;
while (my $line = <ENT_ENS>){
  chomp $line;
  my @row = split(/\t/, $line);
  $entrez{$row[2]}=$row[1];
}
close ENT_ENS;
open ENT_ENS, "</project/shared/bicf_workflow_ref/GRCh38/genenames.txt" or die $!;
my $gn_header = <ENT_ENS>;
my %ensym;
while (my $line = <ENT_ENS>){
  chomp $line;
  my @row = split(/\t/, $line);
  $entrez{$row[3]}=$entrez{$row[4]};
}
close ENT_ENS;
open ENT_ENS, "</project/shared/bicf_workflow_ref/human/gene2ensembl.human.txt" or die $!;
my $ens_header = <ENT_ENS>;
while (my $line = <ENT_ENS>){
  chomp $line;
  my @row = split(/\t/, $line);
  $entrez{$row[2]}=$row[1];
}
close ENT_ENS;

if($opt{fpkm}){
  open FPKM, "<$opt{fpkm}" or die $!;
  open OUTF, ">$opt{prefix}\.data_fpkm.cbioportal.txt" or die $!;
  print OUTF join("\t","Entrez_Gene_Id",$opt{prefix}),"\n";
  my %fpkm;
  my $fpkm_header = <FPKM>;
  while(my $line = <FPKM>){
    chomp $line;
    my ($id,$gene,$ref,$strand,$start,$end,$coverage,$fpkm,$tpm) = split(/\t/,$line);
    my $ensembl = (split(/\./,$id))[0];
    if ($entrez{$ensembl}) {
      $entrezid = $entrez{$ensembl};
    }else {
      $entrezid = $entrez{$gene};
    }
    next unless ($entrezid);
    print OUTF join("\t",$entrezid,$fpkm),"\n"; 
  }
  close OUTF;
}

if($opt{logcpm}){
  open IN, "<$opt{logcpm}" or die $!;
  open OUTL, ">$opt{prefix}\.data_logCPM.cbioportal.txt" or die $!;
  print OUTL join("\t","Entrez_Gene_Id",$opt{prefix}),"\n";
  $fname = basename($opt{logcpm});
  my $sample = (split(/\./,$fname))[0];
  my $command = <IN>;
  my $head = <IN>;
  chomp($head);
  my $total = 0;
  while (my $line = <IN>) {
    chomp($line);
    my @row = split(/\t/,$line);
    my $gene = $row[0];
    my $ct = $row[-1];
    next if($gene =~ m/^__/);
    $cts{$gene}{$sample} = $ct;
    $total += $ct;
  }
  close IN;
  foreach $ens (keys %cts) {
    next unless $entrez{$ens};
    unless ($cts{$ens}) {
      $cts{$ens} = 0;
    }
    $cpm = ($cts{$ens}/$total)*1e6;
    print OUTL join("\t",$entrez{$ens},sprintf("%.2f",log2($cpm))),"\n";
  }
  close OUTL;
}

sub log2 {
    $n = shift @_;
    if ($n < 1) {
	return 0;
    }else {
	return(log($n)/log(2));
    }
}
