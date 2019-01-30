<%@ Page Title="" Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.ContentItemNew" Codebehind="ContentItemNew.aspx.vb" %>

<asp:Content ID="Content1" ContentPlaceHolderID="Content" Runat="Server">
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnCancel" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Cancel %>" />
        </div>
        <div class="body">
            <table class="subfield" cellspacing="0" align="center" role="presentation">
                <tr class="base3 titlerow">
                    <td><%= Resources.Strings.NewContentItem%></td>
                </tr>
                <tr class="inforow">
                    <td><%= Resources.Strings.NewContentItemMessage%></td>
                </tr>
                <tr>
                    <td>
                        <asp:HyperLink runat="server" ID="lnkAttachment"></asp:HyperLink><br />
                        <asp:HyperLink runat="server" ID="lnkDocumentFragment"></asp:HyperLink><br />                      
                        <asp:HyperLink runat="server" ID="lnkImage"></asp:HyperLink><br />
                        <asp:HyperLink runat="server" ID="lnkTextItem"></asp:HyperLink><br />
                    </td>
                </tr>
            </table>
        </div>
    </div>
</asp:Content>

