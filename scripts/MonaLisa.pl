#!/usr/bin/perl -w
use strict;

# use POSIX;

use utf8;
use open qw(:std :utf8);
#use feature "unicode_strings";
#no bytes;

sub PrintNSpaces($) {
        my($total) = (@_);
	my($res) = ("");
	for(my($i) = 0; $i < $total; $i++) {
		$res .= " ";
	}  
	return $res;               
}
        
my($last_str_length) = (0);
sub WPrint($) {
	my($str) = @_;
	print(PrintNSpaces($last_str_length +1)."\r$str\r");
	$last_str_length = length($str);
}  

sub FixBlockRight($$) { 
# Эта функция выравнивает разделитель по правому краю
	my($s_buff, $spliter) = @_;
	$s_buff =~ s/^\n+//;
	$s_buff =~ s/\n+$//;
	my(@block) = split(/\n/, $s_buff);
	my($calc, $s_temp, $s_temp2, $len, $i) = (0, "", "");
	for($i = 0; $i < scalar(@block); $i ++) {
		$block[$i] =~ s/$spliter.*?$//;
		$block[$i] =~ s/\s*$//;
		$len = length($block[$i]);
		$calc = $len if ($len > $calc);	
#		$block[$i] .= "-".$len."-".MLengthN($block[$i])."-".MLengthB($block[$i])."";			
	}
	for($i = 0; $i < scalar(@block); $i ++) {
	        $len = $calc - length($block[$i]);
		$s_temp2 .= $block[$i] . PrintNSpaces($len) . "  $spliter\n";					
	}
	return $s_temp2;
}

sub FixBlockMiddle($$) {
# Эта функция выравнивает блок по разделителю, става пробелы слева от разделителя
	my($s_buff, $spliter) = @_;
	$s_buff =~ s/^\n+//;
	$s_buff =~ s/\n+$//;
	my(@block) = split(/\n/, $s_buff);
	my($calc, $s_temp, $s_temp2, $s_temp3, $len) = (0, "", "");
	foreach $s_temp (@block) {
		$s_temp3 = $s_temp;
	        $s_temp3 =~ s/\s*$spliter.*$//;
		$len = length ($s_temp3);
		$calc = $len if ($len > $calc);				
	}
	return $s_buff."\n" if ($calc == 0);
	foreach $s_temp (@block) {
       	        $s_temp =~ s/\s*$spliter(.*)$//;
       	        $s_temp3 = $1;
	        if ($s_temp eq "") {
	        	$len = 0;
	        } else {
	        	$len = $calc - length ($s_temp) + 1;
	        }
		$s_temp2 .= $s_temp . PrintNSpaces($len). "$spliter$s_temp3\n";					
	}
	return $s_temp2;
}

sub FixBlockLeft($$) {
# Эта функция выравнивает блок по разделителю, ставя пробелы в начале строки
	my($s_buff, $spliter) = @_;
	$s_buff =~ s/^\n+//;
	$s_buff =~ s/\n+$//;
	my(@block) = split(/\n/, $s_buff);
	my($calc, $s_temp, $s_temp2, $s_temp3, $len) = (0, "", "");
	foreach $s_temp (@block) {
		$s_temp3 = $s_temp;
	        $s_temp3 =~ s/$spliter.*$//;
		$len = length ($s_temp3);
		$calc = $len if ($len > $calc);				
	}
	if ($calc == 0) {
		return $s_buff."\n";
	}
	foreach $s_temp (@block) {
       	        $s_temp =~ s/^\s*(.*?)\s*$spliter\s*//;
       	        $s_temp3 = $1;
	        if ($s_temp eq "") {
	        	$len = 0;
	        } else {
	        	$len = $calc - length ($s_temp3);
	        }
		$s_temp2 .= PrintNSpaces($len). "$s_temp3$spliter $s_temp\n";					
	}
	return $s_temp2;
}

sub ChangeFile($) {
	my($name) = @_;
	my($bak, $s, $s_old);
	my(@strs);
	my($s_buff, $s_total, $str);

	open(FROMFILE, "<:encoding(UTF-8)", $name) || return "Can't open: ".$name;
#	binmode(FROMFILE);

	$s = join("", <FROMFILE>);
	$s_old = $s;

	WPrint("Changing $name");

# Заменить все табы на пробелы
        $s =~ s/\t/        /g;
# не использовать \r
        $s =~ s/\r//g;
# переупорядочить блок graphics {}
# TODO Учитывать количество пробелов перед блоком, смещать на количество +2 (сейчас всегда 4)
	$s_total = "";
	$s = "graphics \{" . $s;
	@strs = split(/graphics\s*\{/is, $s);
	foreach $str (@strs) {
# templates should be ignored (Symbol '\')
		if($str =~ s/^([^\{\\]+?)\}//is) {
			my($grs) = $1;
# should not be used with a single line strings
			if($grs =~ /\n/s) {
				my(@sub_strs, @sub_strs_with, @sub_strs_without);
				@sub_strs_with = ();
				@sub_strs_without = ();
				@sub_strs = split(/\n/is, $grs);
				for(my($i) = 0; $i < scalar(@sub_strs); $i++) {
					if($sub_strs[$i] =~ /(?<!\s)\:/) {
					        $sub_strs[$i] =~ s/^\s*//;
						@sub_strs_with = (@sub_strs_with, $sub_strs[$i]);
					} else {
					        $sub_strs[$i] =~ s/^\s+$//;
						@sub_strs_without = (@sub_strs_without, $sub_strs[$i]) if ($sub_strs[$i] ne "");
					}
				}	
				@sub_strs_with = sort {uc($a) cmp uc($b)} @sub_strs_with;
				$grs = "\n";
				$grs .= join("\n", @sub_strs_without) . "\n" if(scalar(@sub_strs_without) > 0);
				$grs .= "    ". join("\n    ", @sub_strs_with) . "\n" if(scalar(@sub_strs_with) > 0);
				$grs .= "  ";
			}
			$s_total.= "graphics \{" . $grs . "\}" . $str;
		} else {
			$s_total.= "graphics \{" . $str;
		}
	}
	$s_total =~ s/^graphics\s*\{\s*//is;
	$s_total =~ s/^graphics\s*\{\s*/ /is;
	$s = $s_total;
# Заменить пробелы в начале
        $s =~ s/^(\s+)//g;
        $s =~ s#\n( )+\/\/#\n\/\/#g;
# Заменить пробелы в конце
        $s =~ s/( )+\n/\n/g;
# Поставить ровно 1 пробел в начале перед ///
        $s =~ s#( )*\/\/\/# \/\/\/#g;
# схлопнуть {   return 1; }
        $s =~ s#\)\s*\{\s*(return\s*[0-9a-z_])\;\s*\}#\) \{ $1; \}#g;
# выравнивать блоки с : в начале, например свойства ПС в graphics
	@strs = split(/\n/, $s);
	$s_buff = "";
	$s_total = "";
	foreach $str (@strs) {
		if ($str =~ /^[\{]{0,1}\s+[0-9a-z_\.]+\s*\:\s+/i) { # собрать блок
			$s_buff .="$str\n";
		} else {
			if ($s_buff eq "") {
				$s_total .= "$str\n";
			} else { # расчистить блок
				$s_total .= FixBlockLeft($s_buff, "\:");
				$s_total .= "$str\n";
				$s_buff = "";
			}
		}		
	}
	$s_total .= FixBlockLeft($s_buff, "\:") if ($s_buff ne "");
	$s = $s_total;
# выравнивать блоки с // на конце, например комментарии в стоимости обслуживания 
	@strs = split(/\n/, $s);
	$s_buff = "";
	$s_total = "";
	foreach $str (@strs) {
		if ($str =~ / \/\//) { # собрать блок
			$s_buff .="$str\n";
		} else {
			if ($s_buff eq "") {
				$s_total .= "$str\n";
			} else { # расчистить блок
				$s_total .= FixBlockMiddle($s_buff, " \/\/");
				$s_total .= "$str\n";
				$s_buff = "";
			}
		}		
	}
	$s_total .= FixBlockMiddle($s_buff, " \/\/") if ($s_buff ne "");
	$s = $s_total;
# выравнивать блоки с : на конце, например, в языковых файлах
	@strs = split(/\n/, $s);
	$s_buff = "";
	$s_total = "";
	foreach $str (@strs) {
		if ($str =~ / \:/) { # собрать блок[^ ]
			$s_buff .="$str\n";
		} else {
			if ($s_buff eq "") {
				$s_total .= "$str\n";
			} else { # расчистить блок
				$s_total .= FixBlockMiddle($s_buff, " \:");
				$s_total .= "$str\n";
				$s_buff = "";
			}
		}		
	}
	$s_total .= FixBlockMiddle($s_buff, " \:") if ($s_buff ne "");
	$s = $s_total;
# выравнивать блоки с \ на конце, например блоки подстановки define
	@strs = split(/\n/, $s);
	$s_buff = "";
	$s_total = "";
	foreach $str (@strs) {
		if ($str =~ s/\s*\\$//) { # собрать блок
			$s_buff .="$str\n";
		} else {
			if ($s_buff eq "") {
				$s_total .= "$str\n";
			} else { # расчистить блок
				$s_total .= FixBlockRight($s_buff, "\\");
				$s_total .= "$str\n";
				$s_buff = "";
			}
		}		
	}
	$s_total .= FixBlockRight($s_buff, "\\") if ($s_buff ne "");
	$s = $s_total;
# записать результаты
	close(FROMFILE);
#        $s =~ s/\n/\r\n/igs;
# не создавать файл если ничего не изменилось  
	if($s eq $s_old) {
#		print("File was not changed.\n");
		WPrint("");
		return;		
	} else {
		print("\n");
	}
	open(TOFILE, ">:encoding(UTF-8)", "temp.tmp") || return "Can't open temp file.";
#	binmode(TOFILE);
	print(TOFILE $s); 
	close(TOFILE);
	$bak = $name;
	$bak = substr ($bak, 0, rindex($bak, '.')).".bak";
	if (rename($name, $bak)) {
#		print($name." renamed to ".$bak."\n");
		if (rename ("temp.tmp",$name)) {
#			print("Result saved to ".$name."\n");
			unlink($bak);
		}
	} else {
		print($name." can't be changed. result saved to temp.tmp. ");
	}
}

sub ChangeDir($) {
	my($dir) = @_;
        my (@dirs, @files, $t);
        opendir (DIR,$dir);
       	@dirs=grep {!/^\.+$/ and (-d $dir."/".$_)} readdir DIR;
	closedir DIR;
	foreach $t (@dirs) {
	        ChangeDir($dir."/".$t);
	}
        opendir (DIR,$dir);
        @files = grep {!/^\.+$/ and !(-d "$dir/$_") and ((/\.pnml$/i) || ((/\.lng$/i)))} readdir DIR;
	closedir DIR;
	@files = sort {uc($a) cmp uc($b)} @files;
	foreach $t (@files) {
		ChangeFile($dir."/".$t);
	}
}

sub main()
{
	print("Monalize all pnml files in the current dir and subdirs\nVersion 0.2\n");
        my ($dir);
        use Cwd;
        $dir = cwd();
        $dir =~ s#\\#\/#g;
        $dir =~ s#/$##;
        ChangeDir($dir);
}

main()
#end
