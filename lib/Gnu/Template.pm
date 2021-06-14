#
# StringUtil.pm - 
# 

package Gnu::Template;

use warnings;
use strict;
require Exporter;
use feature 'state';

our @ISA         = qw(Exporter);
our $VERSION     = 0.10;
our @EXPORT      = qw(Template);
our @EXPORT_OK   = qw(Template Usage InitTemplates TemplateKeys);
our %EXPORT_TAGS = (ALL=>[@EXPORT_OK]);


sub Usage
   {
   print Template("usage");
   exit(0);
   }

sub Template
   {
   my ($key, %data) = @_;

   my $templates = InitTemplates();
   my $template = $templates->{$key};
   die "unknown template '$key'" unless defined $templates->{$key};
   $template =~ s{\$(\w+)}{exists $data{$1} ? $data{$1} : "\$$1"}gei;
   return $template;
   }

sub TemplateKeys
   {
   my $templates = InitTemplates();
   return keys %{$templates};
   }

sub InitTemplates
   {
   state $templates;

   return $templates if $templates;
   $templates = {};
   my $key = "nada";
   while (my $line = <main::DATA>)
      {
      my ($section) = $line =~ /^\[(\S+)\]/;
      $key = $section || $key;
      $templates->{$key} = ""      if $section;
      $templates->{$key} .= $line  if !$section;
      }
   return $templates;
   }



1; # two

