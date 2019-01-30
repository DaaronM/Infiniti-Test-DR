<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.UnlockProject" Codebehind="UnlockProject.aspx.vb" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>
     <div id="contentinner" class="base1">
     <asp:UpdatePanel ID="up" runat="server">
     <ContentTemplate>
        <div class="toolbar">
            <asp:Button ID="btnUnlock" runat="server" CssClass="toolbtn" />
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" text="<%$Resources:Strings, Back %>" />
        </div>
        <div class="body">
            <table align="center" cellspacing="0" role="presentation">
                <tr>
                    <td class="cell-normal" width="500px"><b><asp:Label ID="litComment" runat="server" AssociatedControlID="txtComment" /></b></td>
                </tr>
                <tr>
                    <td><asp:TextBox id="txtComment" CssClass="fld" runat="server" Width="500px" /></td>
                </tr>
            </table>
        </div>
         </ContentTemplate>
        </asp:UpdatePanel>
    </div>
</asp:Content>
    