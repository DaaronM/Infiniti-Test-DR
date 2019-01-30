<%@ Page Language="VB" MasterPageFile="~/SubPage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.SelectFolder" Codebehind="SelectFolder.aspx.vb" %>
<asp:Content ID="Content1" ContentPlaceHolderID="ContentPlaceHolder1" Runat="Server">
    <script type="text/javascript">
        function selectFolder(id, name) {
            window.opener.saveFolder(id, name);
            window.close();
        }
        
        function closeMe() {
            window.close();
        }
        
        function clearSelection() {
            window.opener.saveFolder('', '&nbsp;');
            window.close();
        }
    </script>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <input type="button" id="btnClear" class="toolbtn" value="<%=Resources.Strings.ClearSelection %>" onclick="clearSelection()" />
            <input type="button" id="btnClose" class="toolbtn" value="<%=Resources.Strings.Close %>" onclick="closeMe()" />
        </div>
        <div class="body">
            <asp:Repeater ID="rpFolders" runat="server">
                <ItemTemplate>
                    <a href="#void" onclick="selectFolder('<%#DataBinder.Eval(Container.DataItem, "FolderGuid") %>', <%#PrepareName(Container.DataItem) %>);return false;"><%# Microsoft.Security.Application.Encoder.HtmlEncode(Eval("Name"))%></a><br />
                </ItemTemplate>
            </asp:Repeater>
            <br />
        </div>
    </div>
</asp:Content>

