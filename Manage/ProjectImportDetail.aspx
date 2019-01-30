<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.ProjectImportDetail" CodeBehind="ProjectImportDetail.aspx.vb" %>

<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnImport" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Import %>" />
            <span class="tooldiv" id="divImport" runat="server"></span>
            <asp:Button ID="btnCancel" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Cancel %>" CausesValidation="false" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <table align="center" class="editsection" cellspacing="0" role="presentation">
                <asp:Repeater ID="rptFilenames" runat="server">
                    <ItemTemplate>
                        <tr>
                            <td style="width: 100px">
                                <span class="m">*</span><asp:Label ID="lblProjectName" runat="server" Text="<%$Resources:Strings, ProjectName %>"
                                    AssociatedControlID="txtProjectName"></asp:Label></td>
                            <td>
                                <asp:TextBox ID="txtProjectName" runat="server" MaxLength="100" CssClass="fld" Width="500px" Text='<%# Eval("Name")%>'></asp:TextBox>
                                <asp:Label ID="lblProjectNameValue" runat="server" Visible="false"></asp:Label><br />
                            </td>
                        </tr>
                    </ItemTemplate>
                </asp:Repeater>
                <tr>
                    <td>
                        <asp:Label ID="litComment" runat="server" AssociatedControlID="txtComment" /></td>
                    <td>
                        <asp:TextBox ID="txtComment" CssClass="fld" runat="server" Width="500px" /></td>
                </tr>
                 <tr>
                    <td>
                        <span class="m">*</span><asp:Label ID="lblFolder" runat="server" Text="<%$Resources:Strings, FolderNewProject %>" AssociatedControlID="lstFolder"></asp:Label>
                    </td>
                    <td>
                        <asp:DropDownList ID="lstFolder" runat="server" CssClass="fld">
                        </asp:DropDownList>
                    </td>
                </tr>
                <tr>
                    <td>&nbsp;
                    </td>
                    <td>
                        <asp:CheckBox ID="chkOverwrite" runat="server" Text="<%$Resources:Strings, OverwriteExisting %>" /></td>
                </tr>
                <tr>
                    <td>&nbsp;
                    </td>
                    <td>
                        <asp:CheckBox ID="chkOverwriteContentItems" runat="server" Text="<%$Resources:Strings, OverwriteExistingContentItems %>" /></td>
                </tr>
            </table>
        </div>
    </div>
</asp:Content>
