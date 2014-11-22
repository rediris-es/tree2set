#!/usr/bin/perl -w
#
# Conversor de configuraciones de Juniper de forma arbolea a lineas "SET"
# 
# FJMC 2011/08/31


use strict ;
use Getopt::Long;


my $PROGRAM_NAME="tree2set.pl" ;
my $version =2 ;
my $debug= 0 ;
my $help ;
my $ver ;
my $annotate =0 ;
my $nocom = 0 ;

sub debug {
  my $i ;
  if ($debug) {
    foreach $i (@_) { print STDERR  "DEBUG:$i" ; }
  }
}

sub usage {
        print "$PROGRAM_NAME $version < configuracion_JunOS\n\n" ;
        print "Convierte una configuración \"normal/arborea\" de JunOS en formato set\n" ;
        print "--help|ayuda : Muestra esta informacion\n" ;
        print "--version    : Version del programa\n";
	print "--debug      : modo de depuración\n" ;
	print "--nocom      : Quita los comentarios /*...*/ de las lineas set\n" ;
	print "--annotate   : Quita los comentarios /*...*/ de las lineas set y pone al final el texto la secuencia de comandos\n" ;
	exit 0 ;
}

sub version {
        print "$PROGRAM_NAME  $version\n" ; exit ;
        }
my $res= GetOptions (
        "ayuda|help" =>\$help ,
        "version" => \$ver ,
        "debug!" => \$debug,
	"annotate" =>\$annotate,
	"nocom" => \$nocom
        ) ;

if ($help) { usage() ; }
if ($ver) { version() ; }


sub remove_somments {
	my $linea = $_[0] ;
	if (( $nocom ==1) || ($annotate) ==1) {
			debug "linea antes $linea" ;
			$linea =~ /(.*)\/\*.*\*\/(.*)/$1$2/ ;
			debug "linea despues $linea" ;
	}
	return ($linea) ;
	}

my @tokens ;

my @pila ;


my $comment="" ;

my $texto="" ;

my $sucio=0  ;
my $intxt=0 ;

my $txt ;
my $com_mode ;

my $ntc ;

push @pila, "0" ;
while (my $linea= <STDIN>) {
	chomp $linea ;
	$com_mode = 0 ;
	$ntc=0 ;
	debug "Parting linea : $linea\n" ;
	debug "estado : num elemntos " . scalar @tokens  . " , tokens = @tokens, pila=@pila\n" ;
	my @tmp = split /\s+/, $linea ;
	for (my $tk =0 ; $tk !=@tmp ; $tk ++) {
		next if ($com_mode ==1) ;
		my $tok = $tmp[$tk] ;
		next if (($tok =~ /\s+/ ) || ($tok eq "")) ;
		if  ($tok eq "{") {
			next if ($com_mode ==1) ;
			my $num = @tokens ;
		#	elsif ( ($linea =~ /\s+family\s+iso\s+\{/)  || ($linea =~ /\s+family\s+ine.*\s\{/) ) { $num=$num-1 ; }
			push @pila, $num ;
			debug "Found { apilado $num tokens = @tokens \n" ;
			next ;
			} 
		elsif ($tok =~ /.*;/) {
			next if ($com_mode ==1) ;
			debug "Found ;\n" ; 
			$tok =~ s/;//g ;
			if ($intxt==1) { $tok = $txt . $tok ; $intxt=0 ; $txt="" ;  } 
			push @tokens, $tok ;
			$texto= "set " ;			
			for (my $j=0 ; $j != @tokens ;  $j++ ) { $texto .= $tokens[$j] . " "  ;}
			$sucio =0  ;
			print  remove_comments ($texto) . "\n" ;	
			# Limpiamos la pila 
			my $l= @pila ;
			my $num=0 ;
			if ($l > 0 ) { $num = pop @pila ; push @pila, $num ; } else  {$num=0 ; }
			my $numelem= @tokens ;
			for (my $j = $numelem ; $j!= $num ; $j-- ) { my $nada= pop @tokens ; } 
			debug "Estado: tokens= @tokens, pila=@pila \n";
			$ntc=1 ;
			next ;
		}
		elsif ($tok eq "}") {
			next if ($com_mode ==1) ;
			my $num=  pop @pila ;
			if ($sucio == 1) { 
				$texto="(sucio)set " ;
				for (my $j=0 ; $j != @tokens ;  $j++ ) { $texto .= $tokens[$j] . " "  ;}
				debug "$texto\n" ;
				}
				$sucio=0 ;
#			my $numelem= @tokens ;
#			for (my $j = $numelem+1 ; $j!= $num  ; $j-- ) { my $nada= pop @tokens ; }
#			$numelem = @tokens ;
		
			my $numelem = pop @pila ;
			push @pila, $numelem ;
			while  ( scalar (@tokens) > $numelem ) { my $nada= pop @tokens ;  }

			debug  "found } nuevo nivel = " . scalar @tokens . ", tokens =@tokens, pila =@pila\n" ;
			next ;
		}
		elsif ( $tok =~ /#/) {	
			debug  "comentario \n" ;
			$com_mode=1 ;
			next ;
		}
		elsif ( $tok =~ /.*".*/) {
			next if  ($com_mode == 1) ; 
			# descripciones, etc
			debug "Econtrado texto, intxt=$intxt\n" ;
			$txt .= $tok ;
			if ($intxt=="0") { $intxt=1 ; }
			else { $intxt=0 ; push @tokens, $txt ; $txt="" ;}
			next ;
		}
		else {
			if ($com_mode != 1 )  { 
			if ($intxt==0 ) { 
			push @tokens, $tok ;
			my $numelem= @tokens ;
			debug "Apilamos token $tok , num elementos= $numelem tokens = @tokens , pila = @pila\n" ;
			}
			else { $txt.= $tok ;}
			}
		}
		}
}
