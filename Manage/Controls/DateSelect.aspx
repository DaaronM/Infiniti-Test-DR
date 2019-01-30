<%@ Page Language="vb" AutoEventWireup="false" Inherits="Intelledox.Manage.DateSelect" Codebehind="DateSelect.aspx.vb" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
	<head runat="server">
        <meta charset="utf-8" />
		<title><%= Resources.Strings.SelectDate%></title>
		<style type="text/css">
			BODY { FONT-SIZE: 8pt; FONT-FAMILY: verdana }
			TABLE { FONT-SIZE: 8pt; FONT-FAMILY: verdana }
		</style>
	</head>
	<body bottommargin="0" leftmargin="0" topmargin="0" rightmargin="0">
		<form id="Form1" method="post" runat="server">
		    <asp:HiddenField ID="hidCurrentSelected" runat="server" />
			<table id="Table1" style="height: 244px" cellspacing="1" cellpadding="1" border="0" role="presentation">
				<tr>
					<td colspan="2"><asp:calendar id="CalCalendar" runat="server" font-underline="True" cssclass="normtext" cellpadding="4"
							bordercolor="Black" font-names="Verdana" daynameformat="Shortest" backcolor="White" forecolor="Black"
							width="224px" height="217px" font-size="10pt">
							<todaydaystyle forecolor="Black" backcolor="LightSkyBlue"></todaydaystyle>
							<selectorstyle backcolor="Yellow"></selectorstyle>
							<daystyle font-size="10pt" font-names="verdana"></daystyle>
							<nextprevstyle verticalalign="Bottom"></nextprevstyle>
							<dayheaderstyle font-size="7pt" font-names="Verdana" font-bold="True" backcolor="LightSteelBlue"></dayheaderstyle>
							<selecteddaystyle font-bold="True" forecolor="White" backcolor="LightGray"></selecteddaystyle>
							<titlestyle font-size="10pt" font-names="Verdana" font-bold="True" forecolor="White" backcolor="#42ACD6"></titlestyle>
							<weekenddaystyle backcolor="AliceBlue"></weekenddaystyle>
							<othermonthdaystyle font-names="verdana" forecolor="Silver"></othermonthdaystyle>
						</asp:calendar></td>
				</tr>
				<tr id="monthrow" runat="server">
					<td align="right" style="HEIGHT: 33px"><%=Resources.Strings.ChooseMonth%></td>
					<td style="HEIGHT: 33px"><asp:dropdownlist id="ddlMonth" runat="server" cssclass="normtext" autopostback="True"></asp:dropdownlist>&nbsp;</td>
				</tr>
				<tr id="yearrow" runat="server">
					<td align="right"><%=Resources.Strings.ChooseYear%></td>
					<td><asp:dropdownlist id="ddlYear" runat="server" cssclass="normtext" autopostback="True"></asp:dropdownlist></td>
				</tr>
				<tr>
					<td align="center" colspan="2">
						<asp:label id="lblError" runat="server" cssclass="normtextred"></asp:label></td>
				</tr>
			</table>
		</form>
	</body>
</html>
