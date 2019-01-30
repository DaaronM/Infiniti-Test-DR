<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.CustomFieldEdit" Codebehind="CustomFieldEdit.aspx.vb" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" Runat="Server">
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnSave" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Save %>" />
            <Controls:DeleteButton ID="btnDelete" runat="server" CssClass="toolbtn" CausesValidation="False" TabIndex="25"></Controls:DeleteButton>
            <span class="tooldiv"></span>
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>" CausesValidation="false" />
        </div>
        <div class="body">
            <asp:HiddenField ID="fieldId" runat="server" ClientIDMode="Static" />
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <table align="center" class="editsection" cellspacing="0" role="presentation">
                <tr>
                    <td>
                        <span class="m">*</span><asp:Label ID="lblTitle" runat="server" Text="<%$Resources:Strings, Title %>"
                            AssociatedControlID="txtTitle"></asp:Label></td>
                    <td>
                        <asp:TextBox ID="txtTitle" runat="server" MaxLength="100" CssClass="fld"></asp:TextBox><asp:RequiredFieldValidator
                            ID="valTitle" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtTitle" CssClass="wrn"></asp:RequiredFieldValidator></td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblLocation" runat="server" Text="<%$Resources:Strings, Location %>"
                            AssociatedControlID="lstLocation"></asp:Label></td>
                    <td>
                        <asp:DropDownList ID="lstLocation" runat="server" CssClass="fld" AutoPostBack="true" OnSelectedIndexChanged="lstLocation_SelectedIndexChanged">
                        </asp:DropDownList></td>
                </tr>
                <tr id="trType" runat="server">
                    <td>
                        <asp:Label ID="lblType" runat="server" Text="<%$Resources:Strings, Type %>"
                            AssociatedControlID="lstType"></asp:Label></td>
                    <td>
                        <asp:DropDownList ID="lstType" runat="server" CssClass="fld" AutoPostBack="true">
                            <asp:ListItem Value="0" Text="<%$Resources:Strings, Text %>" />
                            <asp:ListItem Value="1" Text="<%$Resources:Strings, DateString %>" />
                            <asp:ListItem Value="3" Text="<%$Resources:Strings, Image %>" />
                        </asp:DropDownList></td>
                </tr>
            </table>
        </div>
    </div>
</asp:Content>

