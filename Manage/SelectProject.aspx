<%@ Page Language="VB" MasterPageFile="~/SubPage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.SelectProject" Codebehind="SelectProject.aspx.vb" %>
<asp:Content ID="Content1" ContentPlaceHolderID="ContentPlaceHolder1" Runat="Server">
    <script type="text/javascript">
        function selectProject(id, name) {
            if (<%=Microsoft.Security.Application.Encoder.JavaScriptEncode(Request.QueryString("WriteBackId"))%> == '') {
                window.opener.saveProject(<%=Microsoft.Security.Application.Encoder.JavaScriptEncode(Request.QueryString("Type")) %>, id, name);
                <%if Request.QueryString("Type") = 2 Then %>
                    window.opener.document.getElementById('hidUpdateLayout').value = "1";
                <%Else %>
                    window.opener.document.getElementById('hidUpdateTemplate').value = "1";
                <%End If %>
                window.opener.document.forms[0].submit();
            }
            window.close();
        }
        
        function closeMe() {
            window.close();
        }
        
        function clearSelection() {
            selectProject('', '\xa0');
        }
    </script>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <input type="button" id="btnClear" class="toolbtn" value="<%=Resources.Strings.ClearSelection %>" onclick="clearSelection()" />
            <input type="button" ID="btnClose" class="toolbtn" value="<%=Resources.Strings.Close %>" onclick="closeMe()" />
        </div>
        <div class="body">
            <asp:Repeater ID="rpProjects" runat="server">
                <ItemTemplate>
                    <a href="#void" onclick="selectProject('<%#DataBinder.Eval(Container.DataItem, "ProjectGuid") %>', <%#PrepareName(Container.DataItem) %>);return false;"><%# Microsoft.Security.Application.Encoder.HtmlEncode(Eval("Name"))%></a><br />
                </ItemTemplate>
            </asp:Repeater>
            <br />
        </div>
    </div>
</asp:Content>

