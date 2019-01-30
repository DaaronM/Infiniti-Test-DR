<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.ProjectImport" Codebehind="ProjectImport.aspx.vb" %>

<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnUpload" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, Upload %>" />
            <span class="tooldiv" id="divImport" runat="server"></span>
            <asp:Button ID="btnBack" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, Back %>" CausesValidation="false" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <table align="center" class="editsection" cellspacing="0" role="presentation">
                <tr>
                    <td>
                        <span class="m">*</span><asp:Label ID="lblFile" runat="server" Text="<%$Resources:Strings, ProjectFile %>"
                            AssociatedControlID="fileUpload"></asp:Label></td>
                    <td>
                        <asp:FileUpload ID="fileUpload" runat="server" Width="400px" /><asp:RequiredFieldValidator
                            ID="valFileUpload" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="fileUpload" CssClass="wrn"></asp:RequiredFieldValidator></td>
                </tr>
            </table>
        </div>
    </div>
</asp:Content>
